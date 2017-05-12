package Catalyst::View::Component::jQuery;

use 5.008_000;

use warnings;
use strict;
use Carp ('croak');
use Moose::Role;
requires qw( render );

=begin foolcpants

use warnings;
use strict;

=cut

use JavaScript::Framework::jQuery;

our $VERSION;
$VERSION = '0.05';

has '_jquery_obj' => (
    is => 'ro',
    isa => 'JavaScript::Framework::jQuery',
    lazy_build => 1,
);

sub _build__jquery_obj {
    my ( $self ) = @_;

    my $cfg = $self->config;
    my @try_key = qw(
        JavaScript::Framework::jQuery
        Catalyst::View::Component::jQuery
    );
    my @tried;

    for my $key (@try_key) {
        if (exists $cfg->{$key}) {
            $cfg = $cfg->{$key};
            last;
        }
        else {
            push @tried, $key;
        }
    }

    unless (defined $cfg) {
        local $" = ', ';
        croak "No configuration found in config hash, tried: @tried";
    }

    my %optional;

    if (exists $cfg->{xhtml}) {
        $optional{xhtml} = $cfg->{xhtml};
    }
    if (exists $cfg->{plugins}) {
        $optional{plugins} = $cfg->{plugins};
    }

    my $obj;
    eval {
        $obj = JavaScript::Framework::jQuery->new(
            transient_plugins => 1,
            library => $cfg->{library},
            %optional,
        );
    };
    if ($@) {
        croak "JavaScript::Framework::jQuery constructor failed because $@";
    }
    unless ($obj) {
        croak "JavaScript::Framework::jQuery constructor failed but did not give a reason.";
    }

    return $obj;
}

=head1 NAME

Catalyst::View::Component::jQuery - Add a JavaScript::Framework::jQuery object to TT Views

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 package MyApp::View::TT;

 use Moose;
 extends 'Catalyst::View::TT';
 with 'Catalyst::View::Component::jQuery';

In your Controller:

 $c->view('TT')->jquery->construct_plugin(
    name => 'Superfish',
    target_selector => '#navbar',
 );

I<#navbar> is the document id of a UL element containing navigation links.

See L<CatalystX::Menu::Suckerfish> for one method for generating such a
UL element automatically by decorating C<action> methods with
attributes.

In your template:

 [% jquery.script_src_elements %]
 [% jquery.link_elements %]

 [% jquery.document_ready %]

Will insert something like:

 <link type="text/css" href="/css/jquery-ui.css" rel="stylesheet" media="all" />
 <link type="text/css" href="/css/superfish.css" rel="stylesheet" media="all" />
 <script type="text/javascript" src="/js/jquery.js" />
 <script type="text/javascript" src="/js/superfish.js" />

 <script type="text/javascript">
 <![CDATA[
 $(document).ready(function (){
 $("#foobar").superfish();
 });
 ]]>
 </script>

=cut

=head1 DESCRIPTION

This role lazily constructs a L<JavaScript::Framework::jQuery> object and provides an
interface to that object to the role consumer (your Catalyst::View::TT View component).

To use this role, you must use L<Moose> in your View component:

 package MyApp::View::TT;

 use Moose;
 extends 'Catalyst::View::TT';
 with 'Catalyst::View::Component::jQuery';

Lazy construction means that the JavaScript::Framework::jQuery object is not
allocated until the accessor is called. If you don't use the C<jquery> method
in your template the object will not be created.

=cut

=head1 CONFIGURATION

The package config hash supplied to your View module should contain a
'JavaScript::Framework::jQuery' key with a valid
L<JavaScript::Framework::jQuery> configuration hash.

If the JavaScript::Framework::jQuery key isn't found, a key named
'Catalyst::View::Component::jQuery' is searched for.

If neither key is found an exception is raised.

If you're using Catalyst::Plugin::ConfigLoader in your application
the configuration may be included in your application .conf file,
application module (via __PACKAGE__->config(...)) or any other location
ConfigLoader searches for configurations.

Calling __PACKAGE__->config() in the application module is probably
the best alternative. The expression of an array of anonymous hash
references has proven difficult in the human-readable config
formats.

See L<JavaScript::Framework::jQuery> for a description of the data that
must be included in the config hash.

=head1 METHODS

=cut

=head2 render( ) [around]

A Moose C<around> method modifier wraps the Catalyst::View::TT render method so
we can add the C<jquery> method in templates:

 # in your template

 [% jquery.script_src_elements %]

 # will insert your <script src="..." /> markup elements.

See L<Moose::Manual::MethodModifiers> for more information.

=cut

around 'render' => sub {
    my $next = shift;
    my ($self, $c, @args) = @_;
    # stash method called 4 times
    $c->stash->{jquery} = sub { $self->_jquery_obj };
    $self->$next( $c, @args );
};

no Moose::Role;

=head2 jquery( )

Adds C<jquery> method to the role-consuming View component:

 # in your Controller:

 $c->view('TT')->jquery->construct_plugin(...);

=cut

sub jquery {
    $_[0]->_jquery_obj;
}

1; # End of Catalyst::View::Component::jQuery

=pod

=head1 AUTHOR

David P.C. Wollmann, C<< <converter42 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-role-jquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Component-jQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::Component::jQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Component-jQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Component-jQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Component-jQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Component-jQuery/>

=back

=cut

=head1 SEE ALSO

L<JavaScript::Framework::jQuery>, L<CatalystX::Menu::Suckerfish>, L<Moose>, L<Moose::Role>, L<Catalyst>, L<perl>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 David P.C. Wollmann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

