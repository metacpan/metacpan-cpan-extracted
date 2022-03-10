##----------------------------------------------------------------------------
## Class Generic - ~/lib/Class/Promise.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/08
## Modified 2022/03/08
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Class::Promise;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Promise::Me );
    our @EXPORT_OK = @Promise::Me::EXPORT_OK;
    our %EXPORT_TAGS = %Promise::Me::EXPORT_TAGS;
    our @EXPORT = @Promise::Me::EXPORT;
    our $VERSION = 'v0.1.0';
};

sub import
{
    my $class = shift( @_ );
    my $hash = {};
    for( my $i = 0; $i < scalar( @_ ); $i++ )
    {
        if( $_[$i] eq 'debug' || 
            $_[$i] eq 'debug_code' || 
            $_[$i] eq 'debug_file' ||
            $_[$i] eq 'no_filter' )
        {
            $hash->{ $_[$i] } = $_[$i+1];
            CORE::splice( @_, $i, 2 );
            $i--;
        }
    }
    # $class->export_to_level( 1, @_ );
    Promise::Me->export_to_level( 1, @_ );
    #local $Exporter::ExportLevel = 1;
    $class->SUPER::import( @_ );
    #Promise::Me->SUPER::import( @_ );
    # $class->export_to_level( 1, @_ );
    $hash->{debug} = 0 if( !CORE::exists( $hash->{debug} ) );
    $hash->{no_filter} = 0 if( !CORE::exists( $hash->{no_filter} ) );
    $hash->{debug_code} = 0 if( !CORE::exists( $hash->{debug_code} ) );
    Filter::Util::Call::filter_add( bless( $hash => ( ref( $class ) || $class ) ) );
    my $caller = caller;
    my $pm = 'Promise::Me';
    for( qw( ARRAY HASH SCALAR ) )
    {
        *{"${caller}\::MODIFY_${_}_ATTRIBUTES"} = sub
        {
            my( $pack, $ref, $attr ) = @_;
            {
                if( $attr eq 'Promise_shared' )
                {
                    my $type = lc( ref( $ref ) );
                    if( $type !~ /^(array|hash|scalar)$/ )
                    {
                        warnings::warn( "Unsupported variable type '$type': '$ref'\n" ) if( warnings::enabled() || $DEBUG );
                        return;
                    }
                    &{"${pm}\::share"}( $ref );
                }
            }
            return;
        };
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Class::Promise - Class Generic

=head1 SYNOPSIS

    use Class::Promise;
    my $this = Class::Promise->new || die( Class::Promise->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
