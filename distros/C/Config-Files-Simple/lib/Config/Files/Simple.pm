package Config::Files::Simple;

=encoding UTF-8
 
=head1 NAME
 
Config::Files::Simple - Yet another config file reader.

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';    # VERSION

use utf8;
use strict;
use warnings;
use vars qw/$VERSION @EXPORT_OK/;
require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw( config config_file);
our $_hr_config;

=head1 EXPORT

=over 4

=item * config

=back

=head1 SUBROUTINES/METHODS

=head2 config

Read configuration file from current path.
It needs a YAML file.

=cut

sub config {
    $_hr_config = _check_hashref( $_[0] ) if ( $_[0] );
    return $_hr_config if $_hr_config;
    if ( -f 'config.yaml' ) {
        return config_file( 'config.yaml', 'YAML' );
    }
    elsif ( -f 'config.yml' ) {
        return config_file( 'config.yml', 'YAML' );
    }
    else {
        require Carp;
        Carp::cluck('could not find a config.yml or config.yaml file');
        die;
    }
}

=head2 config_file

Read configuration file from given path.

=cut

sub config_file {
    if ( -f $_[0] && defined $_[1] ) {
        require Module::Load;
        my $loading_package = "Config::Files::Simple::$_[1]";
        Module::Load::load $loading_package;
        $_hr_config = _check_hashref( $loading_package->new->config_file( $_[0] ) );
        return $_hr_config;
    }
    else {
        require Carp;
        Carp::cluck("could not find $_[0] file");
    }
    return undef;
}

=head2 _check_hashref

private hashref checking sub

=cut

sub _check_hashref {
    require Ref::Util;
    return $_[0] if ( Ref::Util::is_hashref( $_[0] ) );
    require Carp;
    Carp::cluck('config data must be a hashref');
}

1;

__END__

=pod
 
=head1 SYNOPSIS
 
Sample if no config file is given
    
    ...
    use Config::Files::Simple qw/config config_file/;

    #set your config
    Config::Files::Simple::config({ key => 'value'});
    

    #read config from specific file
    Config::Files::Simple::config_file('/path/to/config.yml', 'YAML');

    ...

=head1 DESCRIPTION
 
Simple and stupid config reader.
 
=head1 CONFIGURATION
 
Configuration can be automatically parsed from a `config.yaml` or `config.yml`
file  in the current working directory, or it can be explicitly set with the
C<config> function:
 
    Config::Files::Simple::config({ key => 'value'});
 
If you want the config to be autoloaded from a yaml config file, just make sure
to put your config data under a top level C<git_sugar> key.
 
=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Config-Files-Simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-Files-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Files::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-Files-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Files-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-Files-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Files-Simple/>

=back

=head1 SEE ALSO
 
=over 4
 
=item L<Config::File>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

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
