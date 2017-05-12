package Dancer2::Plugin::Auth::YARBAC::Provider::Base;

use strict;
use warnings;

use Moo;
use namespace::clean;
use Crypt::PBKDF2;
use Data::Dumper;

our $VERSION = '0.011';

has dsl                   => ( is => 'ro' );
has app                   => ( is => 'ro' );
has settings              => ( is => 'ro' );
has pw_min_length         => ( is => 'ro', default => \&_pw_min_length, lazy => 1 );
has pw_max_length         => ( is => 'ro', default => \&_pw_max_length, lazy => 1 );
has pw_special_characters => ( is => 'ro', default => \&_pw_special_characters, lazy => 1 );
has pw_control_characters => ( is => 'ro', default => \&_pw_control_characters, lazy => 1 );
has pw_no_repeating       => ( is => 'ro', default => \&_pw_no_repeating, lazy => 1 );
has pw_upper_case         => ( is => 'ro', default => \&_pw_upper_case, lazy => 1 ); 
has pw_lower_case         => ( is => 'ro', default => \&_pw_lower_case, lazy => 1 );
has pw_numbers            => ( is => 'ro', default => \&_pw_numbers, lazy => 1 );
has pw_required_score     => ( is => 'ro', default => \&_pw_required_score, lazy => 1 );
has pw_truncate           => ( is => 'ro', default => \&_pw_truncate, lazy => 1 );
has hash_class            => ( is => 'ro', default => sub { 'HMACSHA2' } );
has hash_args             => ( is => 'ro', default => sub { { sha_size => 512, } } );
has iterations            => ( is => 'ro', default => \&_iterations, lazy => 1 );
has output_len            => ( is => 'ro', default => \&_output_len, lazy => 1 );
has salt_len              => ( is => 'ro', default => \&_salt_len, lazy => 1 );
has pbkdf2                => ( is => 'ro', default => \&_pbkdf2, lazy => 1 );

sub _pw_min_length
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{min_length} 
             && $self->settings->{password_strength}->{min_length} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{min_length}
           : 6;
}

sub _pw_max_length
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{max_length} 
             && $self->settings->{password_strength}->{max_length} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{max_length}
           : 32;
}

sub _pw_special_characters
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{special_characters}   
             && $self->settings->{password_strength}->{special_characters} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{special_characters}
           : 1;
}

sub _pw_control_characters
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{control_characters}
             && $self->settings->{password_strength}->{control_characters} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{control_characters}
           : 1;
}

sub _pw_no_repeating
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{no_repeating}
             && $self->settings->{password_strength}->{no_repeating} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{no_repeating}
           : 1;
}

sub _pw_upper_case
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{upper_case}
             && $self->settings->{password_strength}->{upper_case} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{upper_case}
           : 1;
}

sub _pw_lower_case
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{lower_case}
             && $self->settings->{password_strength}->{lower_case} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{lower_case}
           : 1;
}

sub _pw_numbers
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{numbers}
             && $self->settings->{password_strength}->{numbers} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{numbers}
           : 1;
}

sub _pw_required_score
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{required_score}
             && $self->settings->{password_strength}->{required_score} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{required_score}
           : 25;
}

sub _pw_truncate
{
    my $self = shift;

    return ( defined $self->settings->{password_strength}->{truncate}
             && $self->settings->{password_strength}->{truncate} =~ m{^\d$} )
           ? $self->settings->{password_strength}->{truncate}
           : 1;
}

sub _iterations
{
    my $self = shift;

   return ( defined $self->settings->{PBKDF2}->{iterations} 
            && $self->settings->{PBKDF2}->{iterations} =~ m{^\d^} )
          ? $self->settings->{PBKDF2}->{iterations} 
          : 4000;
}

sub _output_len
{
    my $self = shift;

    return ( defined $self->settings->{PBKDF2}->{output_len} 
             && $self->settings->{PBKDF2}->{output_len} =~ m{^\d$} )
           ? $self->settings->{PBKDF2}->{output_len} 
           : 64;
}

sub _salt_len
{
    my $self = shift;

    return ( defined $self->settings->{PBKDF2}->{salt_len} 
             && $self->settings->{PBKDF2}->{salt_len} =~ m{^\d$} )
           ? $self->settings->{PBKDF2}->{salt_len} 
           : 24;
}

sub _pbkdf2
{
    my $self   = shift;

    return Crypt::PBKDF2->new(
        hash_class => $self->hash_class,
        hash_args  => $self->hash_args,
        iterations => $self->iterations,
        output_len => $self->output_len,
        salt_len   => $self->salt_len,
    );
}

sub generate_hash
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{password} );

    if ( $params->{password} =~ m/^{X-PBKDF2}HMACSHA2.+/ )
    {
        return $params->{password};
    }
    else
    {
        $params->{password} = $self->truncate_password( $params );

        return $self->pbkdf2->generate( $params->{password} );
    }
}

sub validate_password
{
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{hash} || ! defined $params->{password} );

    $params->{password} = $self->truncate_password( $params );

    return ( $self->pbkdf2->validate( $params->{hash}, $params->{password} ) ) ? 1 : undef;
}

sub truncate_password
{
    # Enforcing the truncating of long passwords to avoid DDOS attacks.
    my $self   = shift;
    my $params = shift;
    my $opts   = shift;

    return if ( ! defined $params->{password} );

    return ( $self->pw_truncate ) ? substr( $params->{password}, 0, $self->pw_max_length ) : $params->{password};
}

sub password_strength
{
    my $self      = shift;
    my $params    = shift;
    my $opts      = shift;
    my $password  = $params->{password};
    my $pw_length = ( defined $password ) ? length $password : 0;
    my @errors;

    if ( ! defined $password )
    {
        push( @errors, { code => 1, message => 'Password is empty' } );
    }

    if ( $self->pw_min_length && $pw_length < $self->pw_min_length )
    {
        push( @errors, { code => 2, message => 'Password is too short' } );
    }

    if ( $self->pw_max_length && $pw_length > $self->pw_max_length )
    {
        push( @errors, { code => 3, message => 'Password is too long' } );
    }

    if ( $self->pw_special_characters && $password !~ m{[^a-zA-Z0-9]} )
    {
        push( @errors, { code => 4, message => 'Password must contain special characters' } ); 
    }

    if ( $self->pw_control_characters && $password !~ m{[\n\s]} )
    {
        push( @errors, { code => 5, message => 'Password must contain control characters' } );
    }

    if ( $self->pw_no_repeating && $password =~ m{(\w)(\1+)} )
    {
        my $repeated = length $2;

        if ( $repeated > ( $self->pw_min_length - 2 ) )
        {
            push( @errors, { code => 6, message => 'Password must not be repeating characters' } );
        }
    }

    if ( $self->pw_upper_case && $password !~ m{[A-Z]} )
    {
        push( @errors, { code => 7, message => 'Password must contain at least one uppercase character' } );
    }

    if ( $self->pw_lower_case && $password !~ m{[a-z]} )
    {
        push( @errors, { code => 8, message => 'Password must contain at least one lowercase character' } );
    }

    if ( $self->pw_numbers && $password !~ m{\d} )
    {
        push( @errors, { code => 9, message => 'Password must contain at least one number character' } );
    }

    my $score = 0;
    
    if ( $pw_length > $self->pw_min_length )
    {
        # for every char above min_length award 2 points
        $score += ( ( $pw_length - $self->pw_min_length ) * 2 );
    }

    if ( $self->pw_min_length > 6 )
    {
        # high enforced min
        $score += 2;
    }

    if ( $self->pw_special_characters )
    {
        # enforcing special
        $score += 2;
    }

    if ( $self->pw_control_characters )
    {
        # enforcing control
        $score += 2;
    }

    if ( $self->pw_no_repeating )
    {
        # enforcing no repeating
        $score += 2;
    }

    if ( $self->pw_upper_case )
    {
        # enforcing upper case
        $score += 2;
    }

    if ( $self->pw_lower_case )
    {
        # enforcing lower case
        $score += 2;
    }

    if ( $self->pw_numbers )
    {
        # enforcing num
        $score += 2;
    }

    if ( $password =~ m/(?:.*[^a-zA-Z0-9]){2}/ )
    {
        # at least 2 special chars
        $score += 6;
    }

    if ( $password =~ m/(?:[\n\s]).*(?:[\n\s])/ )
    {
        # at least 2 control chars 
        $score += 6;
    }

    if ( $password =~ m/(?:[a-z].*[A-Z])|(?:[A-Z].*[a-z])/ )
    {
        # got at least 2 combo of upper to lower
        $score += 2;
    }

    if ( $password =~ m/(?:[a-zA-Z].*\d)|(?:\d.*[a-zA-Z])/ )
    {
        # Got at least 1 combo of letters and numbers
        $score += 2;
    }

    if ( $password =~ m/(?:[a-zA-Z0-9].*[^a-zA-Z0-9])|(?:[^a-zA-Z0-9].*[a-zA-Z0-9])/ )
    {
        # got at least 1 combo of letters, nums and specials
        $score += 3;
    }

    my $error = ( ( $self->pw_required_score >= $score ) || defined $errors[0]->{code} ) ? 1 : 0;

    if ( $self->pw_required_score > $score )
    {
        push( @errors, { code => 10, message => 'Password scored ' . $score . ' points, must score at least ' . $self->pw_required_score . ' points' } );        
    }

    return { score => $score, error => $error, errors => \@errors };
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Auth::YARBAC::Provider::Base - Yet Another Role Based Access Control Framework

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This module is the base provier for the YARBAC framework.
See L<Dancer2::Plugin::Auth::YARBAC>.

=head1 AUTHOR

Sarah Fuller <sarah@averna.id.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sarah Fuller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Yet Another Role Based Access Control Framework

