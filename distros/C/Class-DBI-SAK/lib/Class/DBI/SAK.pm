package Class::DBI::SAK;

use vars qw[$VERSION %EXTENSIONS @OVERRIDES];
use Carp;
use strict;
# use warnings;

$VERSION = '1.4';

%EXTENSIONS = (
    ':useful' => {
        'AbstractSearch'       => 'use %s',
        'Pager'                => 'use %s',
    },
    ':mysql'  => {
        'mysql'                 => 'use base qw[%s]',
        'mysql::FullTextSearch' => 'use %s',
    },
    'Extension'   => 'use base qw[%s]',
    'FromCGI'     => 'use %s',
    'Pg'          => 'use base qw[%s]',
    'Replication' => 'use base qw[%s]',
    'SQLite'      => 'use base qw[%s]',
);

$EXTENSIONS{':all'} = { map {
    ref $EXTENSIONS{$_}   ?
    %{$EXTENSIONS{$_}}    :
    ( $_ => $EXTENSIONS{$_} )
} keys %EXTENSIONS };

@OVERRIDES = ( qw[
    Extension mysql Pg Replication SQLite
] );

sub import {
    my ($class, @requests) = @_;
    my $caller  = caller(0);
    my %modules = ();
    my @uses    = ();

    @requests = ':useful' unless @requests;

    foreach my $req ( @requests ) {
        if ( substr( $req, 0, 1 ) eq ':' ) {
            if ( exists $EXTENSIONS{$req} ) {
                $modules{$_} = $EXTENSIONS{$req}->{$_}
                    foreach keys %{$EXTENSIONS{$req}};
            } else {
                croak "$class does not export a $req tag";
            }
        } else {
            if ( exists $EXTENSIONS{':all'}->{$req} ) {
                $modules{$req} = $EXTENSIONS{':all'}->{$req};
            } else {
                croak "$class does not export $req\n";
            }
        }
    }

    while ( my ($name, $use) = each %modules ) {
        push @uses, sprintf $use, "Class::DBI::$name";
    }

    unshift @uses, 'use base qw[Class::DBI]'
        unless grep { exists $modules{$_} } @OVERRIDES;

    @uses = sort { ( () = $b =~ /base/ ) <=> ( () = $a =~ /base/ ) } @uses;

    my $statement  = join ";\n", sort {
        ( () = $b =~ /base/ ) <=> ( () = $a =~ /base/ )
    } @uses;
    $statement .= ";\n";

    eval qq[
        package $caller;
        $statement;
        package $class;
    ];
    croak $@ if $@;
}

1;

__END__

=pod

=head1 NAME

Class::DBI::SAK - Class::DBI Swiss Army Knife (SAK)

=head1 SYNOPSIS

  use Class::DBI::SAK qw[:common :mysql FromCGI];

=head1 ABSTRACT

This module encapsulates the pain and suffering that is importing
Class::DBI and all it's little helper friends.

=head1 DESCRIPTION

By taking the busy work out of using Class::DBI as you see fit,
your code becomes more useful by size.  Most of us end up using at
least a couple Class::DBI extensions in our programs, and it's just
a pain.  Enter the Swiss Army Knife.

This module is intelligent.  It knows how each module is supposed
to be used, and which ones override the need to
C<use base qw[Class::DBI]>.

C<Class::DBI::SAK> is not a subclass of C<Class::DBI>.  If you want
to subclass C<Class::DBI> you do the following.

  use Class::DBI::SAK qw[:useful];
  use base qw[Class::DBI];

Also, C<Class::DBI::SAK> installation recommends that you install the
described in the C<:useful> tag.  No modules described in L<Tags>
or L<Modules> are bundled with this distribution.  They must be installed
by you if you want to use them.

=head2 Tags

Tags may be specified either by groupings, begining with a colon
(C<:>), or by the name of the module following the C<Class::DBI::>
prefix.

Tags are available for all modules in the Class::DBI namepace, where
it makes sense to do so, as of the date of this distribution.

All modules are mentioned without the C<Class::DBI::> prefix for
brevity.

=head3 Groups

=over 4

=item C<:all>

All the modules specified in this module.  This couldn't possibly
be useful to the end user (you) since so many of them conflict.

=item C<:useful>

Modules that are generally useful all the time.  AbstractSearch,
and Pager.  This is the default if no tags are given at all.

=item C<:mysql>

Modules for widened support for Mysql.  mysql, mysql::FullTextSearch.

=back

=head3 Modules

=over 4

=item Extension

=item FromCGI

=item Pg

=item Replication

=item SQLite

=back

=head1 BUGS

First, this module could get out of date easily.  This is due to the
nature of the uses of each of the modules.  They are not consistent,
so I have to know about each one.  Please submit a bug report if you
find this module out of date.

Second, no known bugs.

Send bug reports to http://rt.cpan.org/

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>

=head1 COPYRIGHT

Copyright (c) 2003 Casey West.  All rights reserved.  This program is
free software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Class::DBI>.

=cut
