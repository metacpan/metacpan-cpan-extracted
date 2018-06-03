package App::BatParser;

use utf8;

use Regexp::Grammars;
use Moo;
use namespace::autoclean;

our $VERSION = '0.006';    # VERSION

# ABSTRACT: Parse DOS .bat and .cmd files

has 'grammar' => (
    is      => 'ro',
    default => sub {
        return qr{
           <nocontext:>
           <File>
    
           <rule: File> (?:<[Lines]>\n)*

           <rule: Lines> <Comment> | <Label> | <Statement>

           <rule: Comment> \:\:<Text=Token> | REM <Text=Token>

           <rule: Label> \:(?!:)<Identifier=Token>

           <rule: Statement> \@?<Command>
           
           <rule: Command> (?:<SpecialCommand> || <SimpleCommand=Token>)

           <rule: SpecialCommand> <If> | <Call> | <For> | <Goto> | <Set> | <Echo>

           <rule: Echo> echo (?:<EchoModifier> | <Message=Token>)

           <rule: EchoModifier> off

           <rule: If> If (?:<NegatedCondition> | <Condition>) <Statement>

           <rule: Condition> <Exists> | <Comparison>

           <rule: NegatedCondition> NOT <Condition>

           <rule: Exists> EXIST <Path>

           <rule: Comparison> <LeftOperand=Literal> <Operator> <RightOperand=Literal>

           <rule: Call> call <Token>

           <rule: Goto> Goto <Identifier=Token>

           <rule: Set> set <Variable=Token>=<Value=Token>

           <rule: For> for <Token> DO <Statement>

           <token: Operator> NEQ | EQU | GTR | == | LSS | LEQ | GEQ

           <token: Path> [^:\n\s]+

           <token: Literal> [^\s]+

           <token: Token> [^\n]*

        }xmi;
    }
);

sub parse {
    my $self = shift;
    my $text = shift;

    if ( $^O eq 'MSWin32' ) {

        # First join lines splited in multiple lines
        $text =~ s/\^\n//msg;
    }
    else {
        # First join lines splited in multiple lines
        $text =~ s/\^\r\n//msg;
        $text =~ s/\r\n/\n/msg;
    }

    if ( $text =~ $self->grammar ) {
        return \%/;
    }
    else {
        return ();
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::BatParser - Parse DOS .bat and .cmd files

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Parse DOS .bat and .cmd files

=head1 SYNOPSYS

    use App::BatParser;
    use Path::Tiny;
    use Data::Dumper;

    my $parser = App::BatParser->new;
    my $bat_string = Path::Tiny::path('t/cmd/simple.cmd')->slurp;

    say Dumper($parser->parse($bat_string));

=head1 METHODS

=head2 grammar

Returns the L<Regexp::Grammars>'s grammar

=head2 parse

Parses the text as a bat/cmd file

=head3 Returns

Hash representation of file on success, empty list on fail

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Pablo Rodríguez González.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords eva.dominguez Toby Inkster

=over 4

=item *

eva.dominguez <eva.dominguez@meteologica.com>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=cut
