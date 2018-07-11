use utf8;

package CatalystX::InjectModule;
$CatalystX::InjectModule::VERSION = '0.13';
use Moose::Role;
use namespace::autoclean;
use CatalystX::InjectModule::MI;
use List::MoreUtils qw(uniq);

after 'finalize_config' => sub {
	my $c = shift;

    my $conf = $c->config->{'CatalystX::InjectModule'};

    $c->mk_classdata('mi'); # we will use this name in Catalyst

    # module injector
	my $mi = $c->mi( CatalystX::InjectModule::MI->new(ctx => $c) );

    $mi->load($conf);


};

after 'setup_components' => sub {
	my $c = shift;

    my $conf = $c->config->{'CatalystX::InjectModule'};

    # inject configured modules
    $c->mi->inject($conf->{inject});

    # add all templates to all views
    # XXX : Change this
    if ( $c->view('TT') ) {
        my @tmpl_paths = @{ $c->view('TT')->config->{INCLUDE_PATH} };
        foreach my $viewfile ( @{$c->mi->_view_files} ) {
            $viewfile =~ /\/View\/(\w*)\.pm/;
            my $view = $1;
            next if ( $view eq 'TT');
            @{ $c->view($view)->config->{INCLUDE_PATH} } = uniq(@tmpl_paths);
        }
    }

    # push templates path (.../root/static/)
    if ( $c->mi->_static_dirs ) {
        push( @{$c->mi->_static_dirs}, 'root/static' )
                  if -d 'root/static';
        foreach my $static_dir ( reverse @{$c->mi->_static_dirs} ) {
            # XXX : And if Static::Simple is not used ?
            $static_dir =~ s|/static||;
            push( @{ $c->config->{'Plugin::Static::Simple'}->{include_path} }, $static_dir );
        }
    }

    # installer
    if ( $c->mi->modules_loaded ) {
        foreach my $module ( @{$c->mi->modules_loaded} ) {
            $c->mi->install_module($module);
        }
    }
};

=encoding utf8

=head1 NAME

CatalystX::InjectModule - injects modules containing components, plugins, config, lib, templates ...

=head1 VERSION

version 0.13

This module is at EXPERIMENTAL stage, so use with caution.

=head1 SYNOPSIS


    use Catalyst qw/
        ConfigLoader
        +CatalystX::InjectModule
    /;

    # myapp.yml
    CatalystX::InjectModule:
      path:
        - t/share/modulesX
        - t/share/modules
      modules:
        - Ax
        - A

    # Each module must have at least one file cxmi_config.yml
    name: Bx
    version: 2
    deps:
      - Cx == 2
      - Ex
    catalyst_plugins:
      - Static::Simple
      - +CatalystX::SimpleLogin


Ce plugin permet d'injecter des 'modules CatalystX::InjectModule' (CI) dans une application Catalyst.

Qu'est ce qu'un module CI ?

Un module CI est défini par son nom et sa version. Si d'autres informations sont enregistrées dans son fichier de configuration 'cxmi_config.yml' elles sont fusionnées avec la config de l'application Catalyst.

Un module CI peut être dépendant d'autres modules CI. Le mot-clé 'deps' est alors utilisé pour les définir :

    deps:
      - OtherModule
      - Another

Un module CI peut être constitué de :

    - librairies Perl : Elles sont dans ce cas ajoutées aux chemins de recherche des librairies (@INC)

    - composants Catalyst ( Model, View, controller ) : Ils sont injectés dans l'application Catalyst

    - plugins Catalyst ( via le mot clé catalyst_plugins du fichier de configuration du module) : Ils sont injectés dans l'application.

    - Fichiers tt dans root/src et root/lib ( Template Toolkit )

    - Un fichier a son nom comportant une fonction 'install' qui sera exécutée lors du chargement. L'installation ne peut se faire qu'une seule fois. Pour réinstaller un Module CI il faut au préalable déinstaller le module.

=head1 AUTHOR

Daniel Brosseau, C<< <dab at catapulse.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-inject at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-InjectModule>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::InjectModule


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-InjectModule>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-InjectModule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-InjectModule>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-InjectModule/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Daniel Brosseau.

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

1; # End of CatalystX::InjectModule
