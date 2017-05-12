package Amon2::Plugin::Web::Woothee;
use strict;
use warnings;

our $VERSION = '0.02';

sub init {
    my ($class, $c, $conf) = @_;

    $c->add_trigger('BEFORE_DISPATCH' => sub {
        my $self = shift;
        $self->{woothee} = Amon2::Plugin::Web::Woothee::Object->new(
            user_agent => $self->req->env->{HTTP_USER_AGENT}
        );
        return;
    });

    Amon2::Util::add_method(
        $c => 'ua_is_pc',
        sub {
            my $self = shift;
            my $category = $self->{woothee}->category || '';
            return 1 if $category eq 'pc';
            return 0;
        },
    );

    Amon2::Util::add_method(
        $c => 'ua_is_crawler',
        sub {
            my $self = shift;
            $self->{woothee}->is_crawler;
        },
    );

    Amon2::Util::add_method(
        $c => 'ua_is_smartphone',
        sub {
            my $self = shift;
            my $category = $self->{woothee}->category || '';
            return 1 if $category eq 'smartphone';
            return 0;
        },
    );

    Amon2::Util::add_method(
        $c => 'ua_is_mobilephone',
        sub {
            my $self = shift;
            my $category = $self->{woothee}->category || '';
            return 1 if $category eq 'mobilephone';
            return 0;
        },
    );

    Amon2::Util::add_method(
        $c => 'ua_is_misc',
        sub {
            my $self = shift;
            my $category = $self->{woothee}->category || '';
            return 1 if $category eq 'misc';
            return 0;
        },
    );

    Amon2::Util::add_method( $c => 'woothee', sub { $_[0]->{woothee} } );
}

1;

package Amon2::Plugin::Web::Woothee::Object;
use strict;
use warnings;
use Woothee;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub user_agent { $_[0]->{user_agent} }

sub name     { $_[0]->_get('name')     }
sub category { $_[0]->_get('category') }
sub os       { $_[0]->_get('os')       }
sub vendor   { $_[0]->_get('vendor')   }
sub version  { $_[0]->_get('version')  }

sub _get {
    my ($self, $key) = @_;

    $self->parse unless exists $self->{parse}{$key};

    return $self->{parse}{$key};
}

sub parse {
    my $self = shift;

    if ( !$self->{parse} || !scalar(keys %{ $self->{parse} }) ) {
        $self->{parse} = Woothee->parse($self->user_agent);
    }
}

sub is_crawler {
    my $self = shift;

    unless ( exists $self->{is_crawler} ) {
        $self->{is_crawler} ||= Woothee->is_crawler($self->user_agent);
    }

    return $self->{is_crawler};
}

1;

__END__

=head1 NAME

Amon2::Plugin::Web::Woothee - The Amon2 Plugin for detecting the User Agent by Woothee


=head1 SYNOPSIS

    package MyApp::Web;
    use Amon2::Web;

    __PACKAGE__->load_plugin('Web::Woothee');


=head1 DESCRIPTION

Amon2::Plugin::Web::Woothee provides some methods for detecting User Agent on context.


=head1 METHODS

=over

=item init

=back

=head1 ADDITIONAL METHODS

You can call below methods on context.

NOTE that these methods are enabled after BEFORE_DISPATCH.

=over

=item ua_is_pc

    $c->ua_is_pc; # If User Agent is PC Browser, it will be 1.

=item ua_is_crawler

=item ua_is_smartphone

=item ua_is_mobilephone

=item ua_is_misc

=item woothee

To get the woothee. You can call the L<Woothee> parameters as the method.

    $c->woothee->name;
    $c->woothee->category;
    $c->woothee->os;
    $c->woothee->vender;
    $c->woothee->version;

=back


=head1 REPOSITORY

Amon2::Plugin::Web::Woothee is hosted on github
<http://github.com/bayashi/Amon2-Plugin-Web-Woothee>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Amon2>, L<Woothee> and L<Plack::Middleware::Woothee>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
