package Config::INI::Reader::Multiline;
$Config::INI::Reader::Multiline::VERSION = '1.002';
use strict;
use warnings;

use Config::INI::Reader 0.024;
our @ISA = qw( Config::INI::Reader );

# preprend the buffer if any
sub preprocess_line {
    my ( $self, $line ) = @_;
    $$line = delete( $self->{__buffer} ) . $$line
      if exists $self->{__buffer} && $$line =~ s/^\s*//;
    return $self->SUPER::preprocess_line($line);
}

sub parse_value_assignment {
    my ( $self, $line ) = @_;
    return if $line =~ /\s*\\\s*\z/;   # handle_unparsed_line does continuations
    return $self->SUPER::parse_value_assignment($line);
}

sub handle_unparsed_line {
    my ( $self, $line, $handle ) = @_;    # order changed in CIR 0.024
    return $self->{__buffer} .= "$line "  # buffer continuations
      if $line =~ s/\s*\\\s*\z// && $line =~ s/\A\s*//;
    return $self->SUPER::handle_unparsed_line( $line, $handle );
}

sub finalize {
    my ($self) = @_;

    # if there's stuff in the buffer,
    # we had a continuation on the last line
    if ( exists $self->{__buffer} ) {
        my $line = delete $self->{__buffer};
        Carp::croak "Continuation on the last line: '$line\\'";
    }

    return $self->SUPER::finalize;
}

1;

__END__

=head1 NAME

Config::INI::Reader::Multiline - Parser for .ini files with line continuations

=head1 SYNOPSIS

If F<act.ini> contains:

    [general]
    conferences = ye2003 fpw2004 \
                  apw2005 fpw2005 hpw2005 ipw2005 npw2005 ye2005 \
                  apw2006 fpw2006 ipw2006 npw2006
    cookie_name = act
    searchlimit = 20

And your program does:

    my $config = Config::INI::Reader::Multiline->read_file('act.ini');

Then C<$config> contains:

    {
        general => {
            cookie_name => 'act',
            conferences => 'ye2003 fpw2004 apw2005 fpw2005 hpw2005 ipw2005 npw2005 ye2005 apw2006 fpw2006 ipw2006 npw2006',
            searchlimit => '20'
        }
    }

=head1 DESCRIPTION

Config::INI::Reader::Multiline is a subclass of L<Config::INI::Reader>
that offers support for I<line continuations>, i.e. adding a
C<< \<newline> >> (backslash-newline) at the end of a line to indicate the
newline should be removed from the input stream and ignored.

In this implementation, the backslash can be followed and preceded
by whitespace, which will be ignored too (just as whitespace is trimmed
by L<Config::INI::Reader>).

=head1 METHODS

All methods from L<Config::INI::Reader> are available, and none extra.

=head1 OVERRIDEN METHODS

The following two methods from L<Config::INI::Reader> are overriden
(but still call for the parent version):

=head2 preprocess_line

Prepends the buffered lines to the current line, and
lets the ancestor method deal with the result.

Note that whitespace at the end of continued lines and at the beginning
of continuation lines is trimmed, and that consecutive lines are joined
with a single space character.

=head2 parse_value_assignment

This method skips lines ending with a C<\> and leaves them to
L</handle_unparsed_line> for buffering.

=head2 handle_unparsed_line

This method buffers the unparsed lines that contain a C<\> at the end,
and calls its parent class version to deal with the others.

=head2 finalize

When the last line has been read and processed, and the buffer is not
empty, this means the last line had a C</> at the end, which is
considered a syntax error.

=head1 ACKNOWLEDGEMENTS

Thanks to Vincent Pit for help (on IRC, of course!) in finding a
descriptive but not too long name for this module.

Thanks to Steve Rogerson for finding out that continuations followed by
an ignorable line were broken, which led to significant code simplication.

=head1 AUTHOR

Philippe Bruhat (BooK), <book@cpan.org>,
who needed to read F<act.ini> files without L<AppConfig>.

=head1 COPYRIGHT

Copyright 2014-2026 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
