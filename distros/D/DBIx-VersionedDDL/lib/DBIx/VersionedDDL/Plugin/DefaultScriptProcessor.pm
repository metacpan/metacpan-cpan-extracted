package DBIx::VersionedDDL::Plugin::DefaultScriptProcessor;

=head1 NAME

DBIx::VersionedDDL::Plugin::DefaultScriptProcessor - default plugin to process version scripts.

Plugins are required to provide a method I<process_script> which takes path to version script as an
argument and returns a list of SQL statements.

=head2 ATTRIBUTES

=over 4

=item * separator. The charactor used to separate (delimit) SQL Statements
in the file. Defaults to I<;> (a semi-colon)

=back

=cut

use Moose::Role;
use Carp;
use Text::CSV;

has 'separator' => (is => 'rw', isa => 'Str', required => 0, default => ';');

=head1 METHODS

=head2 process_script

Returns a list of SQL statements after parsing the supplied script

=cut

sub process_script {

    my ($self, $script) = @_;

    open(my $fh, '<', $script) || croak "Cannot parse $script: $!";
    local $/;
    my $ddl = <$fh>;
    close $fh;
    
    #my $separator = $self->separator;
    #$ddl =~ s/$separator\s+/$separator/g;

    # Naive regexes to remove comments
    $ddl =~ s/(?:--|#).*$/ /mg;

    # C-style comments stolen from File::Comments::Plugin::C
    $ddl =~ s#^\s*/\*.*?\*/(\s*\n)?|
              /\*.*?\*/|
              ^\s*//.*?\n|
              \s*//.*?$
             ##mxsg;

    $ddl =~ s/\r/ /mxg;
    $ddl =~ s/\n/ /mxg;
    $ddl =~ s/\s+/ /mxg;

    # Now split each command based on a semi-colon
    my $csv = Text::CSV->new(
        {
            sep_char           => $self->separator,
            allow_whitespace   => 1,
            allow_loose_quotes => 1
        }
    );

    my @statements;
    if ($csv->parse($ddl)) {
        @statements = $csv->fields;
    }

    return @statements;

}

1;

