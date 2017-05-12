package Catalyst::Plugin::Data::Pensieve;

use strict;
use warnings;

use Data::Pensieve;

our $VERSION = 0.01;

=head1 NAME

Catalyst::Plugin::Data::Pensieve - Easy access to Data::Pensieve within Catalyst applications

=head1 SYNOPSIS

    use Catalyst qw/
        Data::Pensieve
    /;

    __PACKAGE__->config(
        'Plugin::Data::Pensieve' => {
            revision_model      => 'DB::Revision',
            revision_data_model => 'DB::RevisionData',
            definitions         => {
                foo => [ qw/ foo_id name bar baz / ],
            },
        },
    );
    
    sub update_data :Local :Args(3) {
        my ($self, $c, $pk, $key, $value) = @_;
        
        $c->pensieve->store_revisions(
            some_kinda_data => $pk, {
                $key => $value
            }
        );
    }

=cut

sub pensieve
{
    my ($c) = @_;

    my $config = $c->config->{'Plugin::Data::Pensieve'} || {};

    return Data::Pensieve->new(
        revision_rs      => scalar $c->model( $config->{revision_model}      )->search,
        revision_data_rs => scalar $c->model( $config->{revision_data_model} )->search,
        definitions      => $config->{definitions},
    );
}

=head1 AUTHOR

Michael Aquilina <aquilina@cpan.org>

Developed for Grant Street Group's Testafy <http://testafy.com>

=cut

1;


