package App::Unicheck;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Pluggable sub_name => '_plugins', require => 1, search_path => ['App::Unicheck::Modules'];
use Moo;

=head1 NAME

App::Unicheck - Mini data collection framework!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

App::Unicheck is a mini framework to collect data.
The main purpose was to provide a pluggable, easy to use systems data source with consistent interface that is independent from specific systems monitoring solutions but can still be used by them.

On object construction all modules inside the App::Unicheck::Modules namespace are loaded and new() is called on them.

    use App::Unicheck;

    # create object and load modules
    my $unicheck = App::Unicheck->new;

=cut

=head1 ATTRIBUTES

=head2 modules

Hash reference containing all loaded modules with module names as keys and module instances as values.

    # print out loaded modules
    say for keys $unicheck->modules;

=cut

has modules => (
    is => 'rw'
);


=head1 METHODS

=cut

sub BUILD {
    my $self = shift;

    my $modules = {};

    for my $check ($self->_plugins){
        (my $name = $check) =~ s/App::Unicheck::Modules::(.*)/$1/;
        $modules->{$name} = $check->new;
    }

    $self->modules($modules);
}

sub _loaded_modules {
    my $self = shift;

    wantarray ? keys %{$self->modules} : [keys %{$self->modules}];
}

=head2 run

Runs a check module's run() method with parameters.

    $unicheck->run($module, @params);

=cut

sub run {
    my ($self, $module, @params) = @_;

    $self->modules->{$module}->run(@params) if defined $module && defined $self->modules->{$module};
}

=head2 info

Show information on loaded modules. Calls the help() method of the modules and formats the output.

    # show info of all modules
    say $unicheck->info;

    # show info of specific module
    say $unicheck->info($module);

=cut

sub info {
    my ($self, $module) = @_;

    # if called with out specific module get info of all modules
    my @modules = $self->_loaded_modules;
    if (defined $module && $module) {
        @modules = ($module);
    }
    my $info = '';

    for my $module (@modules){
        $info .= "$module (" . $self->modules->{$module}->help->{description} . "):\n";

        # TODO clean up ugly mess
        $info .= (' ' x 2) . "Available actions:\n";
        my %actions = %{$self->modules->{$module}->help->{actions}};
        while (my ($action, $data) = each %actions){
            $info .= (' ' x 4) . "$action ($data->{description}):\n";
            $info .= (' ' x 6) . "Formats:\n";
            my %formats = %{$data->{formats}};
            while (my ($k, $v) = each %formats){
                $info .= (' ' x 8) . "$k: $v\n";
            }
            $info .= (' ' x 6) . "Parameters:\n";
            my %params = %{$data->{params}};
            while (my ($k, $v) = each %params){
                $info .= (' ' x 8) . "$k: $v\n";
            }
        }
    }

    $info;
}

=head1 AUTHOR

Matthias Krull, C<< <<m.krull at uninets.eu>> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-unicheck at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Unicheck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Alternatively report bugs or feature requests at L<https://github.com/uninets/App-Unicheck/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Unicheck


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Unicheck>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Unicheck>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Unicheck>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Unicheck/>

=item * Github

L<https://github.com/uninets/App-Unicheck/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Matthias Krull.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::Unicheck
