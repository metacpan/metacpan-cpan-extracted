package App::BoolFindGrep::Bool;

use common::sense;
use charnames q(:full);
use Carp;
use English qw[-no_match_vars];
use List::Util qw[first];
use Text::Balanced qw[extract_delimited extract_multiple];
use Moo;

our $VERSION = '0.06'; # VERSION

has slash_as_delim => (
    is      => q(rw),
    isa     => sub { ( $_[0] == 0 || $_[0] == 1 ) or die },
    default => 0,
);
has operators => (
    is      => q(ro),
    default => sub {
        {   AND => q(&&),    #
            OR  => q(||),    #
            NOT => q(!),     #
        };
    },
);
has expression => ( is => q(rw), default => undef );
has operands   => ( is => q(rw), default => sub { []; }, );
has parse      => ( is => q(rw), default => sub { []; }, );

sub parse_expr {
    my $self = shift;

    return 1 unless defined $self->expression();
    return 1 if $self->expression() eq q();

    $self->operands(undef);
    $self->parse(undef);

    my @token = $self->tokenizer( $self->expression() );

    return unless $self->lazy_checker(@token);

    $self->operands_collector(@token);
    my @expression = @token;

    $self->parse( [@expression] );

    return 1;
} ## end sub parse_expr

sub tokenizer {
    my $self       = shift;
    my $expression = shift;

    my $op = join qq(\N{VERTICAL LINE}), keys %{ $self->operators() };

    my @expression;
    if ( $self->slash_as_delim() ) {
        @expression = extract_multiple(
            $expression,    #
            [ sub { extract_delimited( $_[0], '/' ) } ],    #
        );
    }
    else {
        @expression = $expression;
        $expression[0] =~ s{\N{SOLIDUS}}{\N{REVERSE SOLIDUS}\N{SOLIDUS}}gmsx;
    }

    foreach (@expression) {

        s{\A\p{IsSpace}}{}msx;
        s{\p{IsSpace}\z}{}msx;

        if (   m{\A\N{SOLIDUS}}msx
            && m{(?<!\N{REVERSE SOLIDUS})\N{SOLIDUS}\z}msx )
        {
            croak sprintf q(Syntax Error in expression: '%s'),
                $self->expression()
                if length() < 3;
            next;
        }

        s{(?<!\\)([()])}        # PARENTHESIS
         {\N{LINE FEED}$1\N{LINE FEED}}gmsx;

        s{(?:\A|\s)(${op})(?=\s|\z)}         # OPERATORS
         {\N{LINE FEED}$1\N{LINE FEED}}gimsx;

        s{\A\p{IsSpace}+}{}msx;
        s{\p{IsSpace}+\z}{}msx;

        s{\N{SPACE}*\N{LINE FEED}+\N{SPACE}*}
         {\N{LINE FEED}}gmsx;

    } ## end foreach (@expression)

    my @token = map { split m{\N{LINE FEED}}msx } @expression;
    @token = grep { defined && $_ ne q() } @token;

    foreach my $token (@token) {
        if (   $token eq qq(\N{LEFT PARENTHESIS})
            || $token eq qq(\N{RIGHT PARENTHESIS}) )
        {
            $token = [ q(PARENTHESIS), $token ];
        }
        elsif ( exists $self->operators->{uc $token} ) {
            $token = [ q(OPERATOR), uc $token ],;
        }
        else {
            if ($token =~    #
                m{\A\N{SOLIDUS}
                   (?<token>.*?)
                   (?<!\N{REVERSE SOLIDUS})\N{SOLIDUS}\z
                  }msx
                )
            {
                $token = $LAST_PAREN_MATCH{token};
            }
            $token =~ s{\N{REVERSE SOLIDUS}\N{SOLIDUS}}
                       {\N{SOLIDUS}}gmsx;

            $token = [ q(OPERAND), $token ];
        } ## end else [ if ( $token eq qq(\N{LEFT PARENTHESIS})...)]
    } ## end foreach my $token (@token)

    return @token;
} ## end sub tokenizer

sub lazy_checker {
    my $self  = shift;
    my @token = splice @_;

    my $status;

    foreach my $token (@token) {
        my ( $name, $value ) = @$token;
        if ( $name eq q(OPERAND) ) {
            $token = 1;
        }
        elsif ( $name eq q(OPERATOR) ) {
            $token = $self->operators->{$value};
        }
        else { $token = $value; }
    }

    my $expression = join qq(\N{SPACE}), @token;
    $EVAL_ERROR = q();
    eval $expression;
    if ($EVAL_ERROR) {
        croak sprintf q(Syntax Error in expression: '%s'),
            $self->expression();
    }
    else { $status = 1; }

    return $status;
} ## end sub lazy_checker

sub operands_collector {
    my $self  = shift;
    my @token = splice @_;

    my %operand;
    foreach my $token (@token) {
        my ( $name, $value ) = @$token;
        next if $name ne q(OPERAND);
        $operand{$value} = 1;
    }

    unless (%operand) {
        croak sprintf q(Syntax Error in expression: '%s'),
            $self->expression();
    }

    $self->operands( [ keys %operand ] );

    return 1;
} ## end sub operands_collector

sub lazy_solver {
    my $self    = shift;
    my %operand = splice @_;

    my @expression;
    foreach my $token ( @{ $self->parse() } ) {
        my ( $name, $value ) = @$token;
        if ( $name eq q(OPERAND) ) {
            $value = $operand{$value};
        }
        elsif ( $name eq q(OPERATOR) ) {
            $value = $self->operators->{$value};
        }
        push @expression, $value;
    }
    my $expression = join qq(\N{SPACE}), @expression;
    my $result = eval $expression;

    return $result;
} ## end sub lazy_solver

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::BoolFindGrep::Bool - parse and/or solve context matching of a boolean expressions.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 expression

Scalar with the original boolean expression.

=head2 lazy_checker

Uses B<Perl>'s interpreter to check syntax of expressions.

=head2 lazy_solver

USes B<Perl>'s interpreter to evaluate the expressions.

=head2 operands

Array reference to a operands' list of I<expression>.

=head2 operands_collector

Search operands and populate I<operands> array reference.

=head2 operators

Dictionary to boolean expressions.

=head2 parse

Array reference with parser processing result of I<expression>.

=head2 parse_expr

Process I<expression>.

=head2 tokenizer

Search and mark tokens to split into an array.

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
