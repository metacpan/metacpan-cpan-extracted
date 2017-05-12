package Bash::Completion::Plugins::cpanm;

# ABSTRACT: Bash completion for cpanm and cpanf
use strict;
use warnings;
use base 'Bash::Completion::Plugin';

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;

use Bash::Completion::Utils qw( command_in_path );

sub should_activate {
    my @commands = qw( cpanm cpanf cpan );
    return [ grep { command_in_path($_) } @commands ];
}

sub generate_bash_setup { return [qw( nospace default )] }

sub complete {
    my ( $class, $req ) = @_;
    my $ua = LWP::UserAgent->new;
    ( my $key = $req->word ) =~ s/::?/-/g;

    #$key =~ s/-$//g;
    my $res = $ua->request(
        POST 'http://api.metacpan.org/release/_search',
        Content => encode_json(
            {   size   => 1000,
                fields => ['distribution'],
                sort   => ['distribution'],
                query  => {
                    filtered => {
                        query  => { match_all => {} },
                        filter => {
                            and => [
                                { prefix => { 'release.distribution' => $key } },
                                { term   => { status        => 'latest' } }
                            ]
                        }
                    }
                }
            }
        )
    );
    eval {
        my $json = decode_json( $res->content );
        $req->candidates('') unless ( $json->{hits} );
        my @candidates;
        my $exact_match = 0;
        for ( @{ $json->{hits}->{hits} } ) {
            my $dist = $_->{fields}->{distribution};
            $exact_match = 1 if ( $key eq $dist );
            $key  =~ s/^(.*)\-.*?$/$1-/;
            $dist =~ s/^\Q$key\E// if ( $key =~ /-/ );
            $dist =~ s/-.*?$/::/g;
            push( @candidates, $dist );
        }
        $req->candidates(@candidates)
            unless ( $exact_match && @candidates == 1 );
    };
}

1;

__END__

=head1 SYNOPSIS

  $ cpanm MooseX::      
  Display all 121 possibilities? (y or n)
  ABC                     Declare                 Object::
  APIRole                 DeepAccessors           OneArgNew
  AbstractFactory         Documenter              POE
  Accessors::             Emulate::               Param
  Aliases                 Error::                 Params::
  Alien                   FSM                     Plaggerize
  AlwaysCoerce            FileAttribute           Policy::
  App::                   File_or_DB::            Privacy
  Async                   FollowPBP               PrivateSetters
  Atom                    Getopt                  Q4MLog
  Attribute::             Getopt::                RelatedClassRoles
  AttributeCloner         GlobRef                 Role::
  AttributeDefaults       Has::                   Runnable
  AttributeHelpers        HasDefaults             Runnable::
  AttributeIndexes        IOC                     Scaffold
  AttributeInflate        InsideOut               SemiAffordanceAccessor
  ...

=head1 DESCRIPTION

L<Bash::Completion> profile for C<cpanm>, C<cpanf> and C<cpan>.

Simply add this line to your C<.bashrc> or C<.bash_profile> file:

 source setup-bash-complete

or run it manually in a bash session.

=head1 METHODS

=head2 complete

Queries C<http://api.metacpan.org> for distributions that match the given name.
Limits the number of results to 1000. Some namespaces might not appear if there
are more than 1000 results for a given query.
