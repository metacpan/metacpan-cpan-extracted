package DBIx::SQLCrosstab::Format;
use strict;
use warnings;
use DBI;
use DBIx::SQLCrosstab;

our $VERSION = '0.7';
# 08-Jan-2004

require 5.006001;

require Exporter;
our @ISA= qw(DBIx::SQLCrosstab);
our @EXPORT=qw();
our @EXPORT_OK=qw();

my %_html_colors = (
    text    => "#009900", # green
    number  => "#FF0000", # red
    header  => "#0000FF", # blue
    footer  => "#000099", # darkblue
);

my %_table_params = (
    border => 1,
    cellspacing => 0,
    cellpadding => 2
);

sub _format {
    my $self = shift;
    my ($str, $what) = @_;
    return $str unless ($self->{add_colors} or $self->{commify});
    my $numeric = $str =~ /^[0-9.]+$/;

    if (($what eq "data") or ($what eq "footer")) {
        if ( $self->{commify} && $numeric )
        {
            if ($str =~ /\./) {
                $str = sprintf("%.2f", $str);
            }
            $str =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/,/g;
        }
    }
    if ($self->{add_colors} ) {
        my $color_type;
        $color_type = $what eq "data" ? $numeric ? "number": "text" : $what;
        $str = qq/<font color="$_html_colors{$color_type}">/ . $str . "</font>";
    }
    return $str;
}

sub _find_headers {
    my $self = shift;
    return seterr("can't create headers before fetching records ")
        unless $self->{recs};
    my $tree = Tree::DAG_Node->new;
    $tree->name('xtab');

    # create headers tree
    for my $name (@{$self->{NAME}}) {
        my $top = $tree;
        for my $lev ( split $self->{query_separator}, $name) {
            my $node;
            ($node) = grep {$_->name eq $lev} $top->daughters;
            unless ($node) {
                $node = Tree::DAG_Node-> new;
                $node->name($lev);
            }
            $top->add_daughter($node);
            $top = $node;
        }
    }

    # add subtotal headers
    $tree->walk_down({
        callback => sub {
            my $node = shift;
            return 1 if $node->address eq "0";
            if ($node->descendants && $self->{col_sub_total}) {
                $node->new_daughter->name("total");
                #$node->new_daughter->name("(". $node->name . ")");
            }
        }
    });

    # find maximum depth
    my $tree_depth = 0;
    $tree->walk_down({
        callback =>sub {
            my $node = shift;
            my $depth = scalar $node->ancestors || 0;
            $tree_depth = $depth if $depth > $tree_depth;
            1;
        }
    });

    # find initial columns without sublevels
    my @header_columns =();
    #@header_columns = map {$_->{alias}} @{$self->{rows}};

    if ($tree_depth> 1) {
        $tree->walk_down({
            callback => sub {
                my $node=shift;
                return 1 if $node->address eq "0";
                if ($node->descendants) {
                    $_[0]->{_end_hc} = 1;
                    return 1
                }
                push @header_columns, $node->name
                    unless $_[0]->{_end_hc};
                my $cur_depth = ($node->address =~ tr/://) -1;
                $node->attributes->{rowspan} = $tree_depth - $cur_depth ;
                #print STDERR  $node->name," ",
                #    $node->attributes->{rowspan},
                #    "\n";
            },
            _end_hc => 0
        });
    }
    else {
        my $recs_rows = $#{$self->{recs}};
        COL:
        for my $col ( 0.. $#{$self->{recs}->[0]} ) {
            my $all_numeric =1;
            for my $row( 0.. $recs_rows) {
                my $value = $self->{recs}[$row][$col];
                $value = 0 unless defined $value;
                unless (($value =~ /^[0-9.]+$/)) 
                {
                    push @header_columns,
                        ($tree->daughters)[$col]->name;
                    $all_numeric =0;
                    next COL;
                }
            }
            last COL if $all_numeric;
        }
    }

    # create the record tree for the initial columns
    my $tree_rec = Tree::DAG_Node->new;
    $tree_rec->name('recs');
    for my $rec (@{$self->{recs}}) {
        my @cols;
        for (0..$#header_columns) {
            push @cols, $rec->[$_];
        }
        my $top = $tree_rec;
        for my $lev ( @cols) {
            my $node;
            ($node) = grep {$_->name eq $lev} $top->daughters;
            unless ($node) {
                $node = Tree::DAG_Node-> new;
                $node->name($lev);
            }
            $top->add_daughter($node);
            $top = $node;
        }
    }

    my @header_formats =();

    # find column span values
    $tree->walk_down( {
        callbackback => sub {
            my $node = shift;
            return 1 unless $node->mother;
            $node->attributes->{colspan} = 1
                unless ($node->descendants);
            $node->mother->attributes->{colspan}
                    += $node->attributes->{colspan};
        }
    });

    # insert values into header format array
    $tree->walk_down({
        callback => sub {
            my $node = shift;
            return 1 if $node->address eq '0';
            my $level = $node->address =~ tr/://;
            $level--;
            my %format = (
                rowspan => 0,
                colspan => $node->attributes->{colspan},
                name    => $node->name
            );
            if (defined $node->attributes->{rowspan}) {
                $format{rowspan} =
                    $node->attributes->{rowspan}
            }
            push @{$header_formats[$level]}, \%format;
        }
    });
    $self->{header_formats} = \@header_formats;

    my %recs_formats =();

    # find row spans values for records
    $tree_rec->walk_down( {
        callbackback => sub {
            my $node = shift;
            return 1 unless $node->mother;
            $node->attributes->{rowspan} = 1
                unless ($node->descendants);
            $node->mother->attributes->{rowspan}
                += $node->attributes->{rowspan};
        }
    });

    # insert values into record format structure
    $tree_rec->walk_down({
        callback => sub {
            my $node = shift;
            return 1 if $node->address eq '0';
            my $level = $node->address =~ tr/://;
            push @{$recs_formats{$level-1}{$node->name}},
                $node->attributes->{rowspan};
        }
    });
    $self->{header_tree} = $tree;
    $self->{recs_tree} = $tree_rec;
    $self->{recs_formats} = \%recs_formats;
    return $self;
}

sub html_header{
    my $self=shift;
    my $html_title = "XTAB";
    if ($self->{title}) {
        $html_title = $self->op_list
            .$self->{title};
    }
    return
            "<html>\n<head>\n"
            ."<title>$html_title</title>\n"
            . "</head>\n"
            ."<body>\n";
}

sub _strip_separator {
    my $self = shift;
    my $str = shift;
    $str =~ s/$self->{query_separator}/ /g;
    return $str;
}

sub as_bare_html {
    my $self = shift;
    return DBIx::SQLCrosstab::seterr("can't create table before record fetching") 
        unless $self->{recs};
    my $html = qq(<table border="$_table_params{border}" cellspacing="$_table_params{cellspacing}" cellpadding="$_table_params{cellpadding}">\n);
    #my $html = qq(<table border="1" cellspacing="0" cellpadding="3">\n);
    $html .= "<tr>";
    $html .= "<td>". $self->_strip_separator($_)."</th>" 
        for @{$self->{NAME}};
    $html .= "</tr>\n";
    for my $rec (@{$self->{recs}}) {
        $html .= "<tr>";
        $html .= "<td>". (defined $_ ? $_ : "-") . "</td>" for @$rec;
        $html .= "</tr>\n";
    }
    $html .= "</table>\n";
    return $html;
}


sub as_html {
    my $self=shift;
    return DBIx::SQLCrosstab::seterr("can't create table before record fetching") 
        unless $self->{recs};
    my $params =shift;
    if ($params) {
        for (qw(complete_html_page only_html_header
             add_colors text_color number_color header_color
             footer_color table_cellpadding table_cellspacing table_border))
        {
            if (exists $params->{$_})
            {
                $self->{$_} = $params->{$_};
            }
        }
    }
    return undef unless $self->_find_headers;
    if ($self->{add_colors}) {
        for (qw(text number header footer)) {
            if (exists $self->{$_."_color"}) {
                $_html_colors{$_} = $self->{$_."_color"};
            }
        }
    }
    for (qw(border cellpadding cellspacing)) {
        if (exists $self->{"table_$_"}) {
            $_table_params{$_} = $self->{"table_$_"}
        }
    }
    my $html ="";
    if ($self->{complete_html_page})
    {
       $html = $self->html_header;
    }
    $html .= qq(<table border="$_table_params{border}" cellspacing="$_table_params{cellspacing}" cellpadding="$_table_params{cellpadding}">\n);
    if ($self->{title_in_header}) {
        my $colspan1 = scalar @{$self->{NAME}};
        $html .= "<tr><th colspan=$colspan1>$self->{title}</th></tr>\n";
    }
    for my $h (@{$self->{header_formats}}) {
        $html .= "<tr>\n";
        for my $col (@$h) {
            my $rowspan = "";
            if (defined $col->{rowspan} )
            {
                $rowspan = "rowspan=$col->{rowspan}";
            }
            $html .=
                "<th $rowspan colspan=$col->{colspan}>"
                . $self->_format($col->{name}, "header")
                . "</th>";
        }
        $html .= "\n</tr>\n";
    }
    if ($self->{only_html_header}) {
        $html .= "</table>\n";
        return $html;
    }

    for my $rec (@{$self->{recs}}) {
        $html .= "<tr>\n";
        my $what = "data";
        if ( $rec->[0]
                && ($rec->[0] =~ /\bzz+\b/)
                || ($rec->[0] eq 'total') ) {
            $what = "footer";
        }
        for (0 .. $#$rec) {
            my %attr =();
            if (defined ($self->{recs_formats}{$_})
                && defined $self->{recs_formats}{$_}{$rec->[$_]})
            {
                if ( @{$self->{recs_formats}{ $_ }{ $rec->[$_] }} )
                {
                    $attr{rowspan} = shift
                        @{$self->{recs_formats}{$_}{$rec->[$_]}};
                }
                else {
                    next;
                }
            }
            #$rec->[$_] = "" unless defined $rec->[$_];
            if ( defined($rec->[$_]) && ($rec->[$_] =~ /^[0-9.]+$/)) {
                $attr{align} = "right";
            }
            my $td = "<td"
                . (join(" ",map( { qq/ $_="$attr{$_}"/} keys %attr)))
                . ">";
            $html .= $td
                . $self->_format( defined $rec->[$_] ? 
                                    $rec->[$_] : "-", $what )
                ."</td>";
        }
        $html .= "\n</tr>\n";
    }
    $html .= "</table>\n";
    if ($self->{complete_html_page}) {
        $html .= $self->html_footer;
    }
    return $html;
}

sub html_footer {
    my $self = shift;
    return "</body>\n"
            ."</html>\n";
}

sub as_xml {
    my $self = shift;
    my $tab = "   ";
    return undef unless $self->_find_headers;
    local $self->{add_colors} = 0;
    my $xml = qq/<?xml version="1.0"?>\n/;
    my $title = $self->{title} || "Crosstab";
    $title =~ s/&/&amp;/g;
    $title =~ s/</&lt;/g;
    $title =~ s/>/&gt;/g;
    $xml .= qq/<xtab title="$title"\n/
         . qq/generator="/ . ref($self) . qq/ version $VERSION">\n/;

    # attach database column labels to header descriptors
    $self->{recs_tree}->walk_down ({
        callback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            $n->attributes->{label} =
                $self->{NAME}->[$_[0]->{_depth}-1];
            1;
        },
        _depth=>0,
    });

    # attach database column labels to record descriptors
    $self->{header_tree}->walk_down ({
        callback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            my $label = $self->{cols}->[$_[0]->{_depth}-1]->{value}?
                $self->{cols}->[$_[0]->{_depth}-1]->{value} :
                $self->{cols}->[$_[0]->{_depth}-1]->{id};
            $n->attributes->{label} = $label;
            1;
        },
        _depth=>0,
    });

    # start producing XML output
    # processing records row by row

    my @records = map {[@$_]} @{$self->{recs}};
    $self->{recs_tree}->walk_down ({
        callback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            if ($n->name eq 'zzzz') {
                $n->name('total');
            }
            $xml .=  $tab x $_[0]->{_depth};
            $xml .=  "<"
                 . $n->attributes->{label}
                 . " name="
                 . '"'
                 . $n->name
                 . '"'
                 . ">\n";
            return 1 if $n->descendants;
            #
            # for each row, a tree of its contents
            # based on the header description
            # is produced
            $xml = $self->_make_xml_line($_[0]->{_depth},
                    $xml, shift @records, $tab);
            1;
        },
         callbackback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            $xml .= $tab x $_[0]->{_depth};
            $xml .= "</"
                 . $n->attributes->{label}
                 . ">\n";
            1;
        },
        _depth => 0,
    });
    $xml .= "</xtab>";
    $xml =~ s{<(\w+)></\1>}{<$1/>}g;
    $xml =~ s{<(\w+)(\s*\S*)>(?:\s*<\w+/>\s*)+</\1>}{<$1$2/>}sg;
    return $xml;
}

sub _make_xml_line {
    my $self   = shift;
    my $depth  = shift;
    my $xml    = shift;
    my $line   = shift;
    my $tab    = shift;
    my $skip   = $depth; # columns to skip in callback
    my $skipb  = $depth; # columns to skip in callbackback
    for (1..$skip) {
        shift @$line;
    }
    $self->{header_tree}->walk_down({
        callback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            return 1 if $skip-- > 0;
            $xml .= $tab x $_[0]->{_depth};
            if ($n->descendants) {
                $xml .= "<"
                     . $n->attributes->{label}
                     . ' name="'
                     . $n->name
                     . '">'
                     . "\n";
                    $_[0]->{_label} = 1;
                    return 1;
            }
            else {
               $xml .= "   <"
                    . $n->name
                    . ">";
                $_[0]->{_label} = 0;
            }
            my $value = shift  @$line;
            if ($value) {
                $value =~ s/zzzz/total/;
            }
            $xml .=   ""
                 . (defined $value? $self->_format($value,"data") : "")
                 . "";
            $_[0]->{_blanks} =0;
        },
        callbackback => sub {
            my $n = shift;
            return 1 unless $n->mother;
            return 1 if $skipb-- > 0;
            if ($_[0]->{_blanks} ) {
                $xml .=  $tab x $_[0]->{_depth};
            }
            else {
                $_[0]->{_blanks} = 1;
            }
            if ($_[0]->{_label} or ($n->descendants)) {
                $xml .= "</". $n->attributes->{label} . ">\n"
            }
            else {
                $xml .= "</" . $n->name . ">\n";
            }
            1;
        },
        _depth => $depth,
        _blanks =>1,
        _label => 1,
    });
    return $xml;
}

sub as_xls {
    my $self = shift;
    my $fname = shift 
        or return DBIx::SQLCrosstab::seterr("File name required to create spreadsheet");
    my $mode = shift || 'straight';
    $mode =~ s/\s*//g;
    my %books = (
        straight  => $mode =~ /^(?:straight|both)$/i,
        transpose => $mode =~ /^(?:transpose|both)$/i
    );
    eval {require Spreadsheet::WriteExcel}; 
    if ($@) {
        return DBIx::SQLCrosstab::seterr("required module Spreadsheet::WriteExcel not found");
    }
    return DBIx::SQLCrosstab::seterr("Recordset not found. Execute query first") 
        unless $self->{recs};
    my $workbook = Spreadsheet::WriteExcel->new($fname)
        or return DBIx::SQLCrosstab::seterr("Error creating spreadsheet");
    my $format = $workbook->add_format(); # Add a format
    $format->set_bold();
    $format->set_text_wrap();
    $format->set_color('blue');
    $format->set_align('center');
    if ($books{straight}) {
        my $worksheet = $workbook->add_worksheet("Crosstab");
        $worksheet->write('A1',[map {
                        join " ", split /$self->{query_separator}/, $_} 
                        @{$self->{NAME}}], $format);
        my $row = 2;
        $worksheet->write('A'. ($row++), $_ ) for @{$self->{recs}};
    }
    if ($books{transpose}) {
        my $worksheet = $workbook->add_worksheet("Transposed");
        my $row =1;
        $format->set_text_wrap(0);
        $format->set_align('left');
        $worksheet->write('A' . ($row++), $_ , $format) for 
                map {join " ", split /$self->{query_separator}/, $_} 
                @{$self->{NAME}};
        $worksheet->write('B1', $self->{recs});
    }
    $workbook->close();
    return $workbook;       
}

sub as_perl_struct {
    my $self = shift;
    my $struct = shift || 'lol';
    return DBIx::SQLCrosstab::seterr("no records to process") 
        unless $self->{recs} and $self->{NAME};
    my %structs = (
        lol  => undef,  # list of lists
        loh  => undef,  # list of hashes (tree-like)
        losh => undef,  # list of simple hashes
        hoh  => undef   # hash of hashes
    );
    return DBIx::SQLCrosstab::seterr ("unrecognized structure $struct")
        unless exists $structs{$struct};
    if ($struct eq 'lol') {
        return $self->{recs};
    }
    my $depth = 1;
    my @splitnames = map {[split /$self->{query_separator}/,$_]} 
        @{$self->{NAME}};

    for (@splitnames) {
        $depth = @$_ if (@$_ > $depth);
    }
    for (@splitnames) {
        while (@$_ < $depth) {
            push @$_, '-';
        }
    }
    my $rowheaders = @{$self->{rows}};
    my %hoh =();
    for my $row (@{$self->{recs}}) {
        if ($struct eq 'losh') {
            my %rec=();
            @rec{@{$self->{NAME}}} = @$row;
            push @{$structs{losh}}, \%rec;
        }
        else {
            my %rec;
            my $count = 0;
            my $rh ="";
            for my $col (@$row) {
                my $value = $col;
                $value = "" unless defined $value;
                $value =~ s/zzzz/total/;
                if ($count < $rowheaders) {
                    $rh .= "{$value}";
                }
                else {
                    my $key = join "", map {"{$_}"} 
                        @{$splitnames[$count]};
                    #print  qq/\$rec$rh - $key = $col\n/;
                    if ($struct eq 'loh') {
                        eval qq/\$rec$rh$key = $value/;
                    }
                    elsif($struct eq 'hoh') {
                        eval qq/\$structs{hoh}{xtab}$rh$key = $value/;
                    }
                }
                $count++;
            }
            push @{$structs{loh}}, \%rec if $struct eq 'loh';
        }
    }
    return $structs{$struct};
}

sub as_csv {
    my $self = shift;
    my $wantheader = shift;
    return DBIx::SQLCrosstab::seterr("no records to process") 
        unless $self->{recs} and $self->{NAME};
    my $csv ="";
    if ($wantheader) {
        $csv .= join ",", map {_quote($_)} 
            @{$self->{NAME}};
        $csv .= "\n";
    }
    for my $row (@{$self->{recs}}) {
        $csv .= join ",", map {
                defined $_ and /^[0-9.]+$/ ? $_ : _quote($_) 
                } @$row;
        $csv .= "\n";
    }
    return $csv;
}

sub as_yaml {
    my $self = shift;
    return DBIx::SQLCrosstab::seterr("no records to process") 
        unless $self->{recs} and $self->{NAME};
    eval {require YAML};
    if ($@){
        return DBIx::SQLCrosstab::seterr('required module YAML not found');
    }
    return YAML::Dump($self->as_perl_struct('hoh'));   
}

sub _quote {
    my $str = shift;
    $str =~ s/\"/\\\"/g if $str;
    return  defined $str ? '"'.$str.'"' : '""' ;
}

1;
__END__

=head1 NAME

DBIx::SQLCrosstab::Format - Formats results created by DBIx::SQLCrosstab

=head1 SYNOPSIS

    use DBIx::SQLCrosstab::Format;
    my $dbh=DBI->connect("dbi:driver:database"
        "user","password", {RaiseError=>1})
            or die "error in connection $DBI::errstr\n";

    my $params = {
        dbh    => $dbh,
        op     => [ [ 'SUM', 'salary'] ],
        from   => 'person INNER JOIN departments USING (dept_id)',
        rows   => [
                    { col => 'country'},
                  ],
        cols   => [
                    {
                       id => 'dept',
                       value =>'department',
                       from =>'departments'
                    },
                    {
                        id => 'gender', from => 'person'
                    }
                  ]
    };
    my $xtab = DBIx::SQLCrosstab::Format->new($params)
        or die "error in creation ($DBIx::SQLCrosstab::errstr)\n";

    my $query = $xtab->get_query("#")
        or die "error in query building $DBIx::SQLCrosstab::errstr\n";

    if ( $xtab->get_recs) {
        # do something with records, or use a built-in function
        # to produce a well formatted HTML table
        #
        print $xtab->as_html;

        print $xtab->as_xml;
        print $xtab->as_yaml;
        print $xtab->as_csv('header');
        $xtab->as_xls("xtab.xls");
        use Data::Dumper;
        print Data::Dumper->Dump ([ $xtab->as_perl_struct('hoh')],
                ['hoh']);
        print Data::Dumper->Dump ([ $xtab->as_perl_struct('losh')],
                ['losh']);
        print Data::Dumper->Dump ([ $xtab->as_perl_struct('loh')],
                ['loh']);
    }
    else {
        die "error in execution $DBIx::SQLCrosstab::errstr\n";
    }

=head1 DESCRIPTION

DBIx::SQLCrosstab::Format is a class descending from DBIx::SQLCrosstab.
Being a child class, it inherits its parent methods and can be used 
in the same way.

In addition, it provides methods to produce formatted output.

=head2 Class methods

=over 4

=item new

=item get_recs

=item get_query

See DBIx::SQLCrosstab docs for usage and a detailed list of parameters 

=item as_html

Returns a formatted HTML table with headers and values properly
inserted, or undef on failure.

=item as_xml

Returns an XML document containing the whole recordset properly
tagged in tree format, or undef on failure.

=item as_xls($filename)

Creates a MS Excel spreadsheet using Spreadsheet::WriteExcel.
Requires a filename (or "-" for stdout).

=item as_perl_struct($mode)

Returns the recordset as a Perl structure. $mode is one of the 
following:
    - lol   List of lists
    - losh  List of simple hashes (one key per column)
    - loh   List of hashes, tree-like, with an appropriate tree
            for each row
    - hoh   Hash of hashes. The resultset as a tree
            (useful to pass to either XML::Simple or YAML)

=item as_yaml

Returns the recordset in YAML format. You must have YAML installed
for this method to work.

=item as_csv($headers)

Returns a text of Comma Separated Values, where each value is
surronded by double quotes (text) or bare (numbers).
If a true value is passed as $header parameter, the first row
contains the list of column names, properly quoted and escaped. 

=back

=head2 Class attributes

In addition to the attributes available in DBIx::SQLCrosstab,
the folowing ones become available in this class.
They may be useful if you want to implement your own
output methods. 

=head2 Extending DBIx::SQLCrosstab::Format

The appropriate way of extending this class is through
inheritance. Just create a descendant of DBIx::SQLCrosstab::Format
and implement your new methods.
The attributes with the relevant information become available 
after a call to the private method _find_headers().

The path to extension is something like the following.

First, create a new module:

 package DBIx::SQLCrosstab::Format::Extended;
 use DBI;
 use DBIx::SQLCrosstab;

 our $VERSION = '0.1';
 require Exporter;
 our @ISA= qw(DBIx::SQLCrosstab::Format);
 our @EXPORT=qw();
 our @EXPORT_OK=qw();

 sub as_myformat {
    my $self = shift;
    return undef unless $self->_find_headers();
    my $new_format = 
    do_something_smart_with($self->{recs_tree},
                      $self->{header_formats});
    return $new_format;
 }

 sub do_something_smart_with {
    my $recs_tree = shift;
    my $header_formats = shift;
    # show off your skills here
 }

 1;

Then, use the new module as you would use the parent one.

    use DBIx::SQLCrosstab::Format::Extended;
    my $dbh=DBI->connect("dbi:driver:database"
        "user","password", {RaiseError=>1})
            or die "error in connection $DBI::errstr\n";

    my $xtab = DBIx::SQLCrosstab::Format::Extended->new($params)
        or die "error in creation ($DBIx::SQLCrosstab::errstr)\n";

    my $query = $xtab->get_query("#")
        or die "error in query building $DBIx::SQLCrosstab::errstr\n";

    if ( $xtab->get_recs) {
        print $xtab->as_myformat;
    }


=over 4

=item {header_formats}

Contains a reference to an array of arrays, one for each level of
headers. Each cell is described with a hash containig name, colspan 
and rowspan values.
Available after a call to _find_headers().

=item {recs_formats}

Contains a refernce to a hash descrbing the structure of the row 
level. Each level contains a list of fields and relative rowspans.
Available after a call to _find_headers().

=item {recs_tree}

Contains a Tree::DAG_Node object with the structure of the column 
headers.  
Available after a call to _find_headers().

=item {header_tree}

Contains a Tree::DAG_Node object with the structure of the row 
headers. 
Available after a call to _find_headers().

=back

=head1 SEE ALSO

L<DBIx::SQLCrosstab>

An article at OnLamp, "Generating Database Server-Side Cross Tabulations" (L<http://www.onlamp.com/pub/a/onlamp/2003/12/04/crosstabs.html>) and one at PerlMonks, "SQL Crosstab, a hell of a DBI idiom" (L<http://www.perlmonks.org/index.pl?node_id=313934>).

=cut
