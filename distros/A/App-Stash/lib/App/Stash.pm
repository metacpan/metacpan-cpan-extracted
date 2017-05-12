package App::Stash;

=head1 NAME

App::Stash - persistent application data storage

=head1 SYNOPSIS

    use App::Stash;
    $stash = App::Stash->new({application => "test"});
    $stash->data->{'test'} = 1;
    $stash->d->{'test'} = 1;

after new run:

    use App::Stash;
    $s=App::Stash->new({application => "test"});
    print $s->data->{'test'}, "\n";
    print $s->dao->test, "\n";

=head1 WARNING

experimental, use on your own risk :-)

=head1 DESCRIPTION

The purpose of the module is to transparently save stash data (structure)
across application (script) execution. The save is done in L</DESTROY>
method. This has certain limitations. Basically make sure you never store
object in the L</data> as this one may get destroyed before L<App::Stash>
object does.

The module+style is inspired by L<App::Cache>. Unlike L<App::Cache> it uses
L<JSON::Util> for storage and not L<Storable>. The stash is saved to
F<$HOME/.app-name/stash.json>. It is in the "pretty" format so it should be
easy to read and edit. I wanted to go with L<Storable> but using it in
DESTROY method causes C<Segmentation fault> on my Perl.

Warn: no file locking in place, use L<Proc::PID::File> or similar to have just one
instance of program running or send a wish list bug report and wait for
implementation of stash file locking. :)

=cut

use warnings;
use strict;

our $VERSION = '0.02';

use File::HomeDir;
use File::Path qw( mkpath );
use Path::Class;
use JSON::Util;


use base qw( Class::Accessor::Chained::Fast );
__PACKAGE__->mk_accessors(qw( application directory stash_filename ));

=head1 PROPERTIES

    application
    directory
    stash_filename

See L<App::Cache/new> for a description of C<application> and C<directory>.
C<stash_filename> is the full path to the file where stash data will be
stored. All three are optional.

=head1 METHODS

=head2 new()

Object constructor.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    unless ( $self->application ) {
        my $caller = (caller)[0];
        $self->application($caller);
    }

    unless ( $self->directory ) {
        my $dir = dir( home(), "." . $self->_clean( $self->application ));
        $self->directory($dir);
    }
    my $dir = $self->directory;
    unless ( -d "$dir" ) {
        mkpath("$dir")
            || die "Error mkdiring " . $self->directory . ": $!";
    }

    unless ( $self->stash_filename ) {
        my $stash_filename = file($self->directory , "stash.json" )->stringify;
        $self->stash_filename($stash_filename);
    }

    return $self;
}

=head2 d

Shortcut for L</data>.

=head2 data

Returns reference to the stash data.

=cut

*d = *data;
sub data {
    my $self = shift;

    $self->load
        if (not $self->{'data'});

    return $self->{'data'};
}

=head2 dao()

Returns L</data> passed to L<Data::AsObject/dao>. So basically the
data structure becomes an object. See L<Data::AsObject> for details.

Note: L<Data::AsObject> is not compile time dependency. It will be used
if installed. If not the exception will be thrown only when calling L</dao>.
So if you plan to use it, make it a dependency of your module/program.

=cut

sub dao {
    my $self = shift;
    if (not $INC{'Data/AsObject.pm'}) {
        eval 'use Data::AsObject;';
        die $@ if $@;
    }
    if (not $INC{'Storable.pm'}) {
        eval 'use Storable;';
        die $@ if $@;
    }
    return Data::AsObject::dao(Storable::dclone($self->data));
}

=head2 clear

Will delete stash data and remove the file with the stash data from the
disk.

=cut

sub clear {
    my $self = shift;
    delete $self->{'data'};
    unlink($self->stash_filename) or die 'failed to unlink '.$self->stash_filename.' - '.$!;
    return;
    
}

=head2 load

Load stash data from disk. Called automatically by first call to L</data>.
Can be used to revert current stash data to the state before current execution.

=cut

sub load {
    my $self = shift;
    $self->{'data'} = eval { JSON::Util->decode([ $self->stash_filename ]) } || {};
    return;
}

=head2 save

Save stash data to disk - F<$HOME/.app-name/stash.json>. Called automatically
via DESTROY method when L<App::Stash> object is going to be destroyed.

Will throw an exception if the file save fails.

=cut

sub save {
    my $self = shift;

    eval { JSON::Util->new->encode($self->data, [ $self->stash_filename ]); };
    die 'failed to save application stash - '.$@
        if $@;
    
    return;
}

=head2 DESTROY

Calls L</save> and prints warning if it fails.

=cut

sub DESTROY {
    my $self = shift;

    eval { $self->save(); };
    warn $@ if $@;
}

sub _clean {
    my ( $self, $text ) = @_;
    $text = lc $text;
    $text =~ s/[^a-z0-9]+/_/g;
    return $text;
}

1;


__END__

=head1 SEE ALSO

L<App::Cache>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-stash at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Stash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Stash


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Stash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Stash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Stash>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Stash/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::Stash
