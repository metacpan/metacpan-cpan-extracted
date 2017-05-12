package C::Sharp::Tokener;
our $ref_name;
our ($ref_line, $line, $col, $current_token, $handle_get_set) = (1,1,1,0,0);

our $VERSION = "0.08062001"; # MCS version number

=head1 NAME

C::Sharp::Tokener - Tokeniser for C#

=head1 SYNOPSIS

    use C::Sharp::Tokener;
    do { 
        ($token, $ttype, $remainder) = C::Sharp::Tokener::tokener($input);
    } while ($input = $remainder)

    use C::Sharp::Parser;
    $parser = new C::Sharp::Parser;
    $parser->YYParse(yylex => \&C::Sharp::Tokener::yy_tokener);

=head1 DESCRIPTION

C# is the new .NET programming language from Microsoft; the Mono project
is an Open Source implementation of .NET. This code, based on the Mono
project, implements a tokeniser for C#. Combined with
C<C::Sharp::Parser> it can be used to create a compiler for C#. 

=head1 SEE ALSO

L<C::Sharp>

=head1 AUTHOR

Simon Cozens (simon@cpan.org)
Based very, very heavily on code by Miguel de Icaza (miguel@gnu.org)

=cut

my %keywords;
my $number;
my $putback_char = -1;
my $val;
my $error_details;

sub location {
    return "Line: $line Col: $col\nVirtLine: $ref_line Token: $current_token ".
        ($current_token eq "ERROR" && "Detail: $error_details");
}

sub properties {
    defined $_[0] ? $handle_get_set = $_[0] : $handle_get_set;
}

sub error { $error_details }
sub Line  { $line }
sub Col   { $col }

$keywords{lc($_)}=$_ for qw{
ABSTRACT AS ADD BASE BOOL BREAK BYTE CASE CATCH CHAR CHECKED CLASS CONST CONTINUE DECIMAL DEFAULT DELEGATE DO DOUBLE
ELSE ENUM EVENT EXPLICIT EXTERN FALSE FINALLY FIXED FLOAT FOR FOREACH GOTO IF IMPLICIT IN INT INTERFACE INTERNAL IS
LOCK LONG NAMESPACE NEW NULL OBJECT OPERATOR OUT OVERRIDE PARAMS PRIVATE PROTECTED PUBLIC READONLY REF RETURN REMOVE
SBYTE SEALED SHORT SIZEOF STATIC STRING STRUCT SWITCH THIS THROW TRUE TRY TYPEOF UINT ULONG UNCHECKED UNSAFE USHORT
USING VIRTUAL VOID WHILE
};

sub is_keyword {
    return 0 if (($_ eq "get" or $_ eq "set") and not $handle_get_set);
    return exists $keywords{$_[0]};
}

sub yy_tokener {
    my $self = shift; # This is a Parse::Yapp object
    my ($token,$ttype);
    ($token, $ttype, $self->YYData->{INPUT}) = tokener($self->YYData->{INPUT});
    return ($ttype, $token);
}

sub tokener {
    $_ = shift;
    my ($allow_keyword) = 0;
    while ($_) {
        s/^\s+//sm;
        if (/^[a-zA-Z_]/) { # Check C# standard - may be Unicode aware
            s/(.\w*)//; 
            return ($1, "IDENTIFIER", $_) if !is_keyword($1) or $allow_keyword;
            return ($1, uc($1), $_);
        }
        if (/^\.\d/ || /^\d/) {
            my $real = 0;
            my $val  = 0;
            if (s/^0[Xx]([A-Fa-f0-9]+)//) {
                $val = hex($1);
                die "Oops: [UL] not handled yet." if /^[ULul]/;
                return ($1, "LITERAL_INTEGER", $_);
            } elsif (s/^(\d+)(\.\D)/$2/) {
                return ($1, "LITERAL_INTEGER", $_);
            } elsif (s/^(\d+\.\d+)//) {
                $real =1;
                $val = $1;
            } else {
                s/(\d+)//; $val = $1;
            }
            $val .= $1 if (s/^([eE][+-]\d+)//);
            if (s/^[fF]//) { return ($val, "LITERAL_FLOAT", $_) }
            if (s/^[dD]//) { return ($val, "LITERAL_DOUBLE", $_) }
            if (s/^[mM]//) { return ($val, "LITERAL_DECIMAL", $_) }
            if (!$real) {
                die "Oops: [UL] not handled yet." if /^[ULul]/;
                return ($val, "LITERAL_INTEGER", $_);
            }
            die "Something went wrong with value $val";
        }
        return (".", "DOT", $_) if s/^\.//;
        s[^//.*][] and next;
        s[^/\*.*?\*/][]ms and next;
        # Handle preprocessor commands here. (Honest)
        return $1, $1, $_ if s#^(
                                    [{}\[\]\(\),:;~\?]
                                |
                                    \+[\+=]?
                                |
                                    -[\-=>]?
                                |
                                    [!=/%^]=?
                                |
                                    ==?
                                |
                                    &[&=]?
                                |
                                    \|[\|=]?
                                | 
                                    <<?=?
                                |
                                    >>?=?
                                )    
                              ##x; # Mighty.
        if (s/^\"([^\\\"]*(?:\\.[^\\\"]*)*)\"//) { # Thank you, Text::Balanced  
            my $string = $1;
#            $string =~ s/\\(.)/"\\$1"/eeg;
            return ($string, "LITERAL_STRING", $_);
        }
        die "Urgh" if /^\"/;
        if (s/^'//) {
            die "CS1011: Empty character literal" if /^'/;
            my $char;
            if (s/^\\(.)//) { $char = eval qq{"\\$1"}; }
            else {s/(.)//; $char = $1 };
            die "CS1012: Too many characters in character literal" if not /^'/;
            return ($char, "LITERAL_CHARACTER", $_);
        }
        ($allow_keyword = 1), next if s/^@//;
        return ("","","") unless $_;
        die "Unrecognised input character: ".substr($_,0,1);
    }
}

1;
