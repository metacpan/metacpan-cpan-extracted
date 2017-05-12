package DB2::db::TableCreator;

use XML::Parser;
use IO::File;

my $data;
my $cur_str = "";
my @depth;

my $cur_table = undef;
my $cur_column = undef;

sub create_table
{
    my $tbl = shift;
    my $xml = shift;

    my $p = XML::Parser->new(
                             Handlers => {
                                 Start => \&tag_start,
                                 End   => \&tag_end,
                                 Char  => \&char,
                             },
                            );

    my $if = IO::File->new($xml, "r");
    die "Can't read $xml: $!" unless $if;

    $p->parse($if);

}

sub tag_start
{
    my $expat = shift;
    my $el    = shift;
    my %attr  = @_;

    unless (scalar @depth or $el eq 'table')
    {
        die "Malformed: outtermost tags must be <table>...</table>";
    }

    if ($el eq 'table')
    {
        $cur_table = { %attr };
    }

    push @depth, $el;
}

sub tag_end
{
    my $expat = shift;
    my $el    = shift;

    die "Malformed: expected </$depth[$#]>, got </$el>" unless $el eq pop @depth;

    if ($el eq 'table')
    {
        # check that it has something useful.
        die "Malformed: table without package"
            unless (exists $cur_table->{package});
        die "Malformed: table with no columns"
            unless exists $cur_table->{column} and scalar @{$cur_table->{column}};
        $cur_table = undef;
    }
}

sub char
{
    my $expat = shift;
    my $str   = shift;

    $cur_str .= $str;
}

1;
