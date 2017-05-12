#!/usr/bin/perl
#
# parse_constants.pl - Parse DB2 <sqlmon.h> and <sqlutil.h> header
#                      files and create perl source code to to look
#                      up information and map numbers to strings
#
# $Id: parse_constants.pl,v 165.3 2009/04/22 14:07:40 biersma Exp $
#

use strict;
use Carp;
use Getopt::Long;

#
# Arguments:
# - basedir: DB2 base directory (defaults to $DB2PATH)
# - outfile: name of output file
#
my %params = ('basedir' => $ENV{DB2PATH},
              'outfile' => 'lib/DB2/Admin/db2_constants.pl',
             );
GetOptions(\%params, qw(basedir=s outfile=s)) ||
  die "Error parsing \@ARGV\n";
foreach my $req (qw(basedir outfile)) {
    next if (defined $params{$req});
    die "Missing required argument -$req\n";
}
die "-basedir $params{basedir}: no such directory\n"
  unless (-d $params{basedir});
my @db2_header_files = map "$params{basedir}/include/$_",
  qw(sqlmon.h sqlutil.h);
foreach my $fname (@db2_header_files) {
    die "$fname: no such file"
      unless (-f $fname);
}

my $constants = parse_header_files(@db2_header_files);
print "Generating db2_constants.pl file...";
generate_perl_code($constants, $params{'outfile'}, @db2_header_files);
print "ok\n";
exit(0);


#
# Parse the constants in the header files, and return a data structure
# mapping constant name to value and comment.  This ignores any
# ifdef/endif statements; if we need those, life will become more
# complex (aka the perl5 MQSeries module).
#
sub parse_header_files {
    my @header_files = @_;
    my %retval;

    print "Parsing DB2 header files...";
    foreach my $fname (@header_files) {
        open (HEADER, $fname) ||
          die "Cannot open header file [$fname]: $!";
        my @lines = <HEADER>;
        chomp @lines;
        close(HEADER);

        while (@lines) {
            my $line = shift @lines;
            $line =~ s/^\s+//;
            next unless ($line =~ /^#define/);

            #
            # Handle lines with continuations (a single backslash at
            # the end of a line)
            #
            while (substr($line, -1) eq '\\') {
                $line =~ s!\s*\\$! !;
                my $next = shift @lines;
                $next =~ s/^\s+//;
                $line .= $next;
            }

            #
            # We may have multi-line comments.  We want to integrate those
            # into a single line for the parsing code.
            #
            if ($line =~ m~/\*(?!.*\*/)~) {
                #
                # Look forward until we find the closing line
                #
                my $count = 0;
                while (defined $lines[$count] &&
                       $lines[$count] =~ m!^\s+[^\*]+\s*$!) {
                    $count++;
                }
                if ($lines[$count] =~ m!^\s+[\(\w].*\*/\s*$!) {
                    #print "Have ", $count+1, "-line run-on comment, joining\n";
		    foreach (0..$count) {
			$lines[$_] =~ s!^\s+! !;
		    }
		    foreach (0..$count) {
			$line .= shift @lines;
		    }
                } else {
                    die "Cannot parse multi-line comment starting at $line";
                }
            }

            my ($name, $value, $type, $comment);
            if ($line =~ m!^\#define\s+\w+\s+/\*! ||
                $line =~ m!^\#define\s+\w+\s*$!) {
                #print "Skip empty constant: $line\n";
                next;
            } elsif ($line =~ m!^#define\s+(\w+)\s+([^\/]+?)\s*$!) {
                #print "Constant with value but no comment: $line\n";
                ($name, $value) = ($1, $2);
            } elsif ($line =~ m!^#define\s+(\w+)\s+([^/]+?)\s*/\*\s*(.*?)\s*\*/\s*$!) {
                #print "Constant with value and C-style comment: $line\n";
                ($name, $value, $comment) = ($1, $2, $3);
            } elsif ($line =~ m!^#define\s+(\w+)\s+([^/]+?)\s*//\s*(.*?)\s*$!) {
                #print "Constant with value and C++-style comment: $line\n";
                ($name, $value, $comment) = ($1, $2, $3);
            } elsif ($line =~ m!^#define\s+(\w+)\(!) {
                #print "Skip macro with arguments: $line\n";
                next;
            } else {
                die "ERROR: cannot parse line [$line]\n";
            }
            if (defined $retval{$name}) {
                die "Duplicate constant [$name]: maybe need #ifdef parsing";
            }

            #
            # In V9.1, some comments start with a number,
            # e.g. '07.List of connections to a DB'.  Remove such
            # leading numbers.
            #
            if (defined $comment &&
                $comment =~ /^\d\d?\.([A-Z].*)$/s) {
                #print "Trim leading number of comment [$comment]\n";
                $comment = $1;
            }

            if ($value =~ m!^-?\d+$!) { # Decimal
                $type = 'Number';
            } elsif ($value =~ m!^\((-?\d+)\)$!) { # Decimal, in parentheses
                $value = $1;
                $type = 'Number';
            } elsif ($value =~ m!^0x[\da-fA-F]+$!) { # Hex
                $type = 'Number';
                $value = hex($value);
            } elsif ($value =~ m!^'[^\']'$!) {
                $type = 'Character';
            } elsif ($value =~ m!^"[^\"]+"$!) {
                $type = 'String';
            } elsif ($value =~ m!^\(\w+\)\(?-?\d+\)?$!) { # Decimal with cast
                $type = 'Expression';
            } elsif ($value =~ m!^sizeof\(\w+.*\)$!) { # Expression
                $type = 'Expression';
            } elsif ($value =~ m!^\(\w+\s*[+-\|]\w+.*\)$!) { # Expression
                #print STDERR "Have complex expression [$value]\n";
                $type = 'Expression';
            } elsif ($value =~ m!^\w+$!) {
                #
                # Hmmm - probably another constant
                #
                if (defined $retval{$value}) {
                    #print "Reference value: [$name] -> [$value]\n";
                    ($value, $type, $comment) =
                      @{ $retval{$value} }{qw(Value Type Comment)};
                } else {
                    #print "Skip reference to unknown constant [$value]: $line\n";
                    next;
                }
            } else {
                die "Cannot parse constant [$value]: $line\n";
            }

            my $category;
            if ($name =~ /^SQLM_ELM_/) {
                $category = 'Element';
            } elsif ($name =~ /^SQLM_PLATFORM_/) {
                $category = 'Platform';
            } elsif ($name =~ /^SQLM_TYPE_/ &&
                     $name ne 'SQLM_TYPE_HEADER') {
                $category = 'Type';
            } elsif ($name =~ /^SQLM_CLASS_/) {
                $category = 'Class';
            } elsif ($name =~ /^SQLM_HEAP_/ &&
                     $name ne 'SQLM_HEAP_MIN' && $name ne 'SQLM_HEAP_MAX') {
                $category = 'Heap';
            } elsif ($name =~ /^SQLM_EVENT_/) {
                $category = 'Event';
            } elsif ($name =~ /^SQLF_(?:DBTN|KTN)_/) {
                $category = 'ConfigParam';
            } elsif ($name =~ /^SQL[FU]_RC_/) {
                $category = 'Reason';
            } elsif ($name =~ /^SQLB_CONT_.*(?:PATH|DISK|FILE)$/) {
                $category = 'ContainerType';
            } elsif (($name =~ /^SQLM_LO..$/ && $name ne 'SQLM_LOAD') ||
                     $name eq 'SQLM_LNON' ||
                     $name eq 'SQLM_LSIX') {
                $category = 'LockMode';
            } elsif ($name =~ /^SQLM_\w+_LOCK$/) {
                $category = 'LockObjectType';
            } elsif ($name =~ /^SQLM_(?:PREPARE|EXECUTE|EXECUTE_IMMEDIATE|OPEN|FETCH|CLOSE|DESCRIBE|STATIC_COMMIT|STATIC_ROLLBACK|FREE_LOCATOR|PREP_COMMIT|CALL|SELECT|PREP_OPEN|PREP_EXEC|COMPILE|SET|RUNSTATS|REORG|REBIND|REDIST|GETTA|GETAA)$/) {
                $category = 'StatementOperation';
            } elsif ($name =~ /^SQLM_(?:STATIC|DYNAMIC|NON_STMT|STMT_TYPE_UNKNOWN)$/) {
                $category = 'StatementType';
            } elsif ($name =~ /^SQLM_\w+_TABLE$/) {
                $category = 'TableType';
            } elsif ($name =~ /^SQLM_UTILITY_\S+$/ &&
                     $name !~ /^SQLM_UTILITY_(STATE|INVOKER)_/ &&
                     $name ne 'SQLM_UTILITY_UNTHROTTLED') {
                $category = 'UtilityType';
            } elsif ($name =~ /^SQLM_HADR_ROLE_/) {
                $category = 'HadrRole';
            } elsif ($name =~ /^SQLM_HADR_STATE_/) {
                $category = 'HadrState';
            } elsif ($name =~ /^SQLM_HADR_CONN_/) {
                $category = 'HadrConnectStatus';
            } elsif ($name =~ /^SQLM_HADR_SYNCMODE_/) {
                $category = 'HadrSyncMode';
            } elsif ($name =~ /^SQLM_REORG_(?:STARTED|PAUSED|STOPPED|COMPLETED|TRUNCATE)$/) {
                $category = 'ReorgStatus';
            }

            #
            # For self-describing data stream elements,
            # use the name as a back-up comment
            #
            if (! defined $comment &&
                $name =~ /^SQLM_ELM_(\w+)$/) {
                $comment = ucfirst(lc $1);
                $comment =~ tr/_/ /;
            }

            $retval{$name}{'Type'} = $type;
            $retval{$name}{'Value'} = $value;
            $retval{$name}{'Comment'} = $comment if (defined $comment);
            $retval{$name}{'Category'} = $category if (defined $category);
        }                       # End while: @lines
    }                           # End foreach: header file
    print "done\n";

    #
    # DB2 switched the various system administratore groups to new
    # configuration elements.  The old ones end on '_GROUP', the new
    # ones end on '_GRP', The documentation still says '_GROUP'.
    #
    # In DB2 V9, this makes a difference, as the code for the old
    # elements doens't handle values over 8 characters correctly.
    # So we replace the '_GROUP' values by the '_GRP' values.
    #
    foreach my $group (qw(SYSADM SYSMAINT SYSCTRL SYSMON)) {
        my $old = "SQLF_KTN_${group}_GROUP";
        my $new = "SQLF_KTN_${group}_GRP";
        if (defined $retval{$old} && defined $retval{$new}) {
            $retval{$old} = delete $retval{$new};
        }
    }

    #
    # For upwards compatibility (and to make the main API work), we
    # define this V8 constant in lower releases
    #
    unless (defined $retval{'SQLM_CLASS_DEFAULT'}) {
        $retval{'SQLM_CLASS_DEFAULT'} =
          { 'Type'    => 'Number',
            'Value'   => 0,
            'Comment' => 'SQLMA is for a standard snapshot',
          };
    }

    return \%retval;
}


#
# Generate perl code with constant information in hashes.  This can be
# included (using 'require') by another module that provides an API.
#
sub generate_perl_code {
    my ($constants, $outfile, @header_files) = @_;

    my $file_names = join("\n", map "#    $_", @header_files);

    open (OUTPUT, "> $outfile") ||
      die "Cannot open output file [$outfile]: $!";

    print OUTPUT <<"_END_";
#
# WARNING: This file is automatically generated.
# Any changes made here will be mercilessly lost.
#
# You have been warned, infidel.
#
# The file has been generated based on the following IBM header file:
#
$file_names
#
# and for the evil hackery used to generate this, see:
#
#    ..../util/parse_constants.pl
#

_END_
  ;

    #
    # Generate hash with all constant info, in alphabetical order
    #
    print OUTPUT "\$constant_info = {\n";
    foreach my $name (sort keys %$constants) {
        print OUTPUT ' ' x 4, "'$name' => {\n";
        my $data = $constants->{$name};
        foreach my $attr (sort keys %$data) {
            my $val = $data->{$attr};
            $val =~ s!'!\\'!g;
            print OUTPUT ' ' x 8, "'$attr' => '$val',\n";
        }
        print OUTPUT ' ' x 4, "},\n";
    }
    print OUTPUT "};\n\n";

    #
    # Generate two-dimensional hash mapping category
    # to number to name
    #
    my %index;
    while (my ($name, $info) = each %$constants) {
        my ($type, $cat, $value) = @{$info}{qw(Type Category Value)};
        next unless (defined $cat && $type eq 'Number');
        $index{$cat}{$value} = $name;
    }

    print OUTPUT "\$constant_index = {\n";
    foreach my $category (sort keys %index) {
        my $l1 = $index{$category};
        print OUTPUT ' ' x 4, "'$category' => {\n";
        foreach my $value (sort { $a <=> $b } keys %$l1) {
            print OUTPUT ' ' x 8, "'$value' => '$l1->{$value}',\n";
        }
        print OUTPUT ' ' x 4, "},\n";
    }
    print OUTPUT "};\n\n";

    print OUTPUT "1;\n";
}
