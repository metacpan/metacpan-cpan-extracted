package App::BoolFindGrep::Grep;

use common::sense;
use charnames q(:full);
use Carp;
use English qw[-no_match_vars];
use IO::File;
use Moo;
use Text::Glob qw[glob_to_regex_string];

our $VERSION = '0.06'; # VERSION

has match_expr => (
    is      => q(rw),
    isa     => sub { die if @_ > 1; die if ref $_[0]; },
    default => undef,
);
has patterns => ( is => q(rw), default => sub { {}; }, );
has greped   => ( is => q(rw), default => sub { {}; }, );
has fixed_strings => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 1 || $_[0] == 0 ) or die; },
    default => 0,
);
has ignore_case => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 1 || $_[0] == 0 ) or die; },
    default => 0,
);
has line_regexp => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 1 || $_[0] == 0 ) or die; },
    default => 0,
);
has word_regexp => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 1 || $_[0] == 0 ) or die; },
    default => 0,
);
has glob_regexp => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 1 || $_[0] == 0 ) or die; },
    default => 0,
);
has content_found => (
    is      => q(rw),
    default => sub { {}; },
);

sub process {
    my $self = shift;
    my @file = splice @_;

    return unless defined $self->match_expr();
    return unless %{ $self->patterns() };

    $self->_process_patterns();

    while ( my $file = shift @file ) {
        croak sprintf q('%s': nonexistent file.), $file if !-e $file;
        croak sprintf q('%s': irregular file.),   $file if !-f $file;
        croak sprintf q('%s': unreadable file.),  $file if !-r $file;
        if ( my $fh = IO::File->new( $file, q(r) ) ) {
            while ( my $line = readline $fh ) {
                chomp $line;
                $self->_search( $line, $file, $fh->input_line_number(), );
            }
        }
        else { croak $OS_ERROR; }
    }

    return 1;
} ## end sub process

sub _search {
    my $self        = shift;
    my $string      = shift;
    my $file        = shift;
    my $line_number = shift;

    foreach my $pattern ( keys %{ $self->patterns } ) {
        my $re = $self->patterns->{$pattern};
        $self->greped->{$file}{$pattern} //= 0;

        if ( $string =~ m{$re} ) {
            $self->greped->{$file}{$pattern}++;
            $self->content_found->{$file}{$line_number} = $string;
        }
    }

    return 1;
} ## end sub _search

sub _process_patterns {
    my $self = shift;

    die if $self->line_regexp() && $self->word_regexp();

    foreach my $pattern ( keys %{ $self->patterns() } ) {
        my $value = $pattern;
        if ( $self->glob_regexp() ) {
            $value = glob_to_regex_string($value);
        }
        else {
            $value = quotemeta $value if $self->fixed_strings();

            if ( $self->line_regexp() ) {
                $value = sprintf q(\A%s\z), $value;
            }
            elsif ( $self->word_regexp() ) {
                $value = sprintf q(\b%s\b), $value;
            }
        }

        $value = $self->ignore_case() ? qr{$value}i : qr{$value};

        $self->patterns->{$pattern} = $value;
    } ## end foreach my $pattern ( keys ...)

    return 1;
} ## end sub _process_patterns

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::BoolFindGrep::Grep - search lines matching a pattern.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 greped

Hash reference to store parsing results.

=head2 match_expr

Scalar with original expression.

=head2 patterns

Hash reference with original operands and processed operands.

=head2 process

Does the work.

=head1 OPTIONS

=head1 ERRORS

=head1 DIAGNOSTICS

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 FILES

=head1 CAVEATS

=head1 BUGS

=head1 RESTRICTIONS

=head1 NOTES

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=head1 HISTORY

=head1 SEE ALSO

=cut
