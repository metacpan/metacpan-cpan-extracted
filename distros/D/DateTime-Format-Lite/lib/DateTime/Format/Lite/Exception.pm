##----------------------------------------------------------------------------
## DateTime Format Lite - ~/lib/DateTime/Format/Lite/Exception.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/04/14
## Modified 2026/04/15
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package DateTime::Format::Lite::Exception;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    if( $] < 5.013 )
    {
        no strict 'refs';
        unless( defined( &warnings::register_categories ) )
        {
            *warnings::_mkMask = sub
            {
                my $bit  = shift( @_ );
                my $mask = "";
                vec( $mask, $bit, 1 ) = 1;
                return( $mask );
            };

            *warnings::register_categories = sub
            {
                my @names = @_;
                foreach my $name ( @names )
                {
                    if( !defined( $warnings::Bits{ $name } ) )
                    {
                        $warnings::Offsets{ $name }  = $warnings::LAST_BIT;
                        $warnings::Bits{ $name }     = warnings::_mkMask( $warnings::LAST_BIT++ );
                        $warnings::DeadBits{ $name } = warnings::_mkMask( $warnings::LAST_BIT++ );
                        if( length( $warnings::Bits{ $name } ) > length( $warnings::Bits{all} ) )
                        {
                            $warnings::Bits{all}     .= "\x55";
                            $warnings::DeadBits{all} .= "\xaa";
                        }
                    }
                }
            };
        }
    }
    warnings::register_categories( 'DateTime::Format::Lite' );
    use vars qw( $VERSION );
    use overload (
        '""'     => \&as_string,
        bool     => sub{1},
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};

sub new
{
    my $this  = shift( @_ );
    my $class = ref( $this ) || $this;
    my %args;
    if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
    {
        %args = %{$_[0]};
    }
    elsif( @_ % 2 == 0 )
    {
        %args = @_;
    }
    else
    {
        $args{message} = shift( @_ );
    }

    my $self = bless(
    {
        message     => $args{message}     // '',
        package     => $args{package}     // '',
        file        => $args{file}        // '',
        line        => $args{line}        // '',
        skip_frames => $args{skip_frames} // 0,
    }, $class );

    # Auto-populate call location unless provided
    unless( $self->{file} && $self->{line} )
    {
        my $skip = $self->{skip_frames} + 1;
        my @info = caller( $skip );
        if( @info )
        {
            $self->{package} ||= $info[0];
            $self->{file}    ||= $info[1];
            $self->{line}    ||= $info[2];
        }
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $msg  = $self->{message} // '';
    if( $self->{file} && $self->{line} )
    {
        $msg .= sprintf( " at %s line %d.\n", $self->{file}, $self->{line} )
            unless( $msg =~ /\n\z/ );
    }
    return( $msg );
}

sub file    { return( $_[0]->{file} ); }
sub line    { return( $_[0]->{line} ); }
sub message { return( $_[0]->{message} ); }
sub package { return( $_[0]->{package} ); }

sub throw
{
    my $class = ref( $_[0] ) ? ref( shift( @_ ) ) : shift( @_ );
    my $e = $class->new( @_ );
    die( $e );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

DateTime::Format::Lite::Exception - Exception object for DateTime::Format::Lite

=head1 SYNOPSIS

    use DateTime::Format::Lite;

    # Exceptions are created automatically by the error() method in various modules
    my $dt = DateTime::Format::Lite->new( year => 2025, month => 13 );
    if( !defined( $dt ) )
    {
        my $err = DateTime::Format::Lite->error;  # DateTime::Format::Lite::Exception object

        # Stringify (overloaded): "Invalid month value (13) at Foo.pm line 5."
        warn "$err";


        printf( "Error: %s\n", $err->message );
        printf( "  at %s line %d\n", $err->file, $err->line );

        # Individual fields:
        printf "Message : %s", $err->message;  # "Invalid month value (13)"
        printf "File    : %s", $err->file;     # "Foo.pm"
        printf "Line    : %d", $err->line;     # 5
        printf "Code    : %s", $err->code // 'n/a';  # optional error code
    }

    # Exception object propagates through method chains
    # When a method fails, it returns a NullObject in chaining (object) context
    # so the chain does not die with "Can't call method on undef":
    my $result = DateTime::Format::Lite->new( %bad_args )->clone->add( days => 1 ) ||
        die( DateTime::Format::Lite->error );

    # pass_error: forwarding an existing exception
    sub my_helper
    {
        my $self = shift( @_ );
        my $tz = DateTime::Format::Lite::TimeZone->new( name => 'Invalid/Zone' ) ||
            return( $self->pass_error );  # re-raise TimeZone's error
        return( $tz );
    }

    my $obj = My::Class->new->my_helper ||
        die( My::Class->error );

    # Fatal mode: turn warnings into exceptions
    my $dt2 = DateTime::Format::Lite->new( year => 2026 );
    $dt2->fatal(1);  # any subsequent error will die() instead of warn()

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

C<DateTime::Format::Lite::Exception> is a lightweight exception class used internally by L<DateTime::Format::Lite>. It is created automatically by the C<error()> method and stored both on the object and in a package-level C<$ERROR> variable.

Unlike L<DateTime>, C<DateTime::Format::Lite> never calls C<die> directly (except via C<throw()>). Instead, error conditions set the exception and return C<undef> in scalar context, or an empty list in list context.

=head1 CONSTRUCTORS

=head2 new( %args | $message )

Constructor. Accepts either a plain string message or a hash with the following keys:

=over 4

=item C<message>

The human-readable error message.

=item C<file>

Source file where the error originated (auto-populated if omitted).

=item C<line>

Line number (auto-populated if omitted).

=item C<package>

Package name (auto-populated if omitted).

=item C<skip_frames>

Number of additional call-stack frames to skip when auto-detecting location.

Default: C<0>.

=back

=head1 METHODS

=head2 as_string

Returns the stringified form of the exception, including file and line information. This method is also invoked by the C<""> overload.

=head2 file

Returns the source file associated with the exception.

=head2 line

Returns the line number associated with the exception.

=head2 message

Returns the error message string.

=head2 package

Returns the package name associated with the exception.

=head2 throw( %args | $message )

Creates a new exception object and immediately calls C<die()> with it.

=head1 SEE ALSO

L<DateTime::Format::Lite>, L<DateTime::Format::Lite::Duration>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
