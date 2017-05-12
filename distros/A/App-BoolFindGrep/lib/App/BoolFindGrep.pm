package App::BoolFindGrep;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use Moo;
use App::BoolFindGrep::Find;
use App::BoolFindGrep::Grep;
use App::BoolFindGrep::Bool;

our $VERSION = '0.06'; # VERSION

has find => (
    is      => q(ro),
    default => sub { App::BoolFindGrep::Find->new(); }
);
has grep => (
    is      => q(ro),
    default => sub { App::BoolFindGrep::Grep->new(); }
);
has bool => (
    is      => q(ro),
    default => sub { App::BoolFindGrep::Bool->new(); }
);
has found_files => (
    is      => q(rw),
    default => sub { []; },
);
has greped_files => (
    is      => q(rw),
    default => sub { []; },
);

sub BUILD {
    my $self = shift;
    my $args = shift;

    foreach my $method ( keys %$args ) {
        foreach my $class (qw[bool find grep]) {
            if ( $self->$class->can($method) ) {
                my $value = delete $args->{$method};
                $self->$class->$method($value);
            }
        }
    }

    die if %{$args};

    return 1;
} ## end sub BUILD

sub process {
    my $self = shift;

    return unless $self->_find_files();
    return unless $self->_grep_files();

    return 1;
}

sub _find_files {
    my $self = shift;

    if ( defined $self->find->file_expr() ) {
        $self->bool->expression( $self->find->file_expr() );
        return unless $self->bool->parse_expr();
        foreach my $operand ( @{ $self->bool->operands() } ) {
            $self->find->patterns->{$operand} = undef;
        }
    }
    return unless $self->find->process();

    if ( defined $self->find->file_expr() ) {
        foreach my $file ( keys %{ $self->find->found() } ) {
            my $operand = $self->find->found->{$file};
            my $result  = $self->bool->lazy_solver(%$operand);
            push @{ $self->found_files() }, $file if $result;
        }
    }
    else { $self->found_files( $self->find->files() ); }

    return 1;
} ## end sub _find_files

sub _grep_files {
    my $self = shift;

    return unless defined $self->grep->match_expr();

    $self->bool->expression( $self->grep->match_expr() );
    return unless $self->bool->parse_expr();

    foreach my $operand ( @{ $self->bool->operands() } ) {
        $self->grep->patterns->{$operand} = undef;
    }
    $self->grep->process( @{ $self->found_files() } );

    foreach my $file ( keys %{ $self->grep->greped() } ) {
        my $operand = $self->grep->greped->{$file};
        my $result  = $self->bool->lazy_solver(%$operand);
        push @{ $self->greped_files() }, $file if $result;
    }

    return 1;
} ## end sub _grep_files

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::BoolFindGrep - find and grep files using boolean expressions.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 found_files

Array reference with files found by B<App::BoolFindGrep::Find> module and processed with B<App::BoolFindGrep::Bool> if B<file_expr> option was given.

=head2 greped_files

Array reference with files found by B<App::BoolFindGrep::Grep> module and processed with B<App::BoolFindGrep::Bool>.

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

=over

=item * L<bool|http://www.gnu.org/software/bool/>

=item * L<find|http://www.gnu.org/software/findutils/>

=item * L<grep|http://www.gnu.org/software/grep/>

=item * L<ack|https://metacpan.org/release/ack>

=item * bfg - module's command line interface.

=back

=for Pod::Coverage BUILD

=cut
