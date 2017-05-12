# $Id: SingletonRows.pm,v 1.10 2008-06-25 14:39:08 cantrelld Exp $

package DBIx::Class::SingletonRows;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use Scalar::Util qw(refaddr);

use base qw(DBIx::Class);

use vars qw(
    $VERSION
    $cache
);

=head1 NAME

DBIx::Class::SingletonRows - make database rows returned by DBIx::Class
into singletons

=head1 DESCRIPTION

When you do this with DBIx::Class:

    my $row = $schema->...

    my $row2 = update_and_return();

    sub update_and_return {
        my $row = $schema->...
        $row->somefield("HLAGH");
        $row->update();
        return $row;
    }

then even if both C<$row> and C<$row2> have the same row_id, they'll have
different values for C<somefield>.  This irritates me, so this mixin fixes it.

=head1 SYNOPSIS

When creating the class that respresents your table, load the 'SingletonRows'
component thus.  Make sure to load it before you load the 'Core' component:

    package MyProject::DB::Employee;

    use base qw(DBIx::Class);

    __PACKAGE__->load_components(qw(SingletonRows Core));

    __PACKAGE__->table('employees');
    ...

=head1 METHODS

It wraps around C<DBIx::Class::Row>'s C<inflate_result()> method so that it
always returns singletons.

=head1 BUGS and WARNINGS

This should be considered to be pre-production code.  It's probably chock
full of exciting data-eating bugs.

=head1 AUTHOR, COPYRIGHT and LICENCE

Written by David Cantrell E<lt>david@cantrell.org.ukE<gt>

Copyright 2008 Outcome Technologies Ltd

This software is free-as-in-speech software, and may be used, distributed,
and modified under the terms of either the GNU General Public Licence
version 2 or the Artistic Licence. It's up to you which one you use. The
full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=cut

$VERSION = '0.11';

sub inflate_result {
    my $self = shift;
    my $row = $self->next::method(@_);
    my $key = join(',', refaddr($row->result_source()->schema()), map { md5_hex($_) } $row->id());
    my $class = ref($row);
    $cache->{$class} ||= {};

    $cache->{$class}->{$key} = $row
        if(!exists($cache->{$class}->{$key}));

    $cache->{$class}->{$key}->{_DCS_refcount} += 1;

    return magick_object($cache->{$class}->{$key});
}

# Unfortunately these magic objects are necessary so that we get the
# required control over reference-counting.  can() and isa() are faked
# up so that in conjunction with AUTOLOAD they appear to inherit from
# the appropriate class.  Anything that directly checks @ISA is going
# to see through the disguise though.

sub magick_object {
    my $object = shift;
    my $class  = ref($object);
    (my $newclass = q[
        package DBIx::Class::SingletonRows::Cached::$class;
        use strict;
        use Digest::MD5 qw(md5_hex);
        use Scalar::Util qw(refaddr);
        use vars qw($AUTOLOAD);

        # use base qw($class); # faked up by the following two lines ...
        sub can { return $class->can($_[1]); }
        sub isa { return $class->isa($_[1]); }

        sub AUTOLOAD {
            (my $sub = $AUTOLOAD) =~ s/.*:://;
            my $self = shift;
            $self->{_obj}->$sub(@_);
        }

        sub DESTROY {
            my $self = shift;
            $self->{_obj}->{_DCS_refcount}--;
            delete $DBIx::Class::SingletonRows::cache
                ->{'$class'}
                ->{join(
                    ',',
                    refaddr($self->{_obj}->result_source()->schema()),
                    map { md5_hex($_) } $self->id()
                )}
              if(!$self->{_obj}->{_DCS_refcount})
        }

        sub _DCS_refcount {
            my $self = shift;
            return $self->{_obj}->{_DCS_refcount};
        }
    ]) =~ s/\$class/$class/g;
    {
        no warnings 'redefine';
        eval $newclass.'package '.__PACKAGE__;
    }
    $object = bless { _obj => $object }, "DBIx::Class::SingletonRows::Cached::$class";
    return $object;
}

1;
