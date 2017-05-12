package Code::CutNPaste::Duplicate;

use Moo;
has 'left'   => ( is => 'ro' );
has 'right'  => ( is => 'ro' );
has 'report' => ( is => 'ro' );
our $VERSION = 0.31;

1;

__END__

=head1 NAME

Code::CutNPaste::Duplicate - Possible duplicate code

=head1 SYNOPSIS

    my $duplicate = Code::CutNPaste::Duplicate->new(
        left => Code::CutNPaste::Duplicate::Item->new(
            file => $filename_left,
            line => $line_number_left,
            code => $text_of_code_left,
        },
        right => Code::CutNPaste::Duplicate::Item->new(
            file => $filename_right,
            line => $line_number_right,
            code => $text_of_code_right,
        },
        report => $code_to_report.
    );

=head1 DESCRIPTION

This is merely a simple object to report possibly duplicated code. For
internal use only.

=head1 VERSION

0.31

=head1 METHODS

=head2 C<left>

The first C<Code::CutNPaste::Duplicate::Item> which may contain duplicate
code.

=head2 C<right>

The second C<Code::CutNPaste::Duplicate::Item> which may contain duplicate
code.

=head2 C<report>

A nicely formatted left/right comparison of possibly duplicated code. For example:

 sub add_line_numbers {                                                                          | sub provide_line_numbers {
     my $contents = prefilter(shift @_);                                                         |     my $lines = prefilter(shift @_);
     my $with_varnames = prefilter(shift @_);                                                    |     my $lines_orig = prefilter(shift @_);
     my @contents;                                                                               |     my @contents;
     my $line_num = 1;                                                                           |     my $line_num = 1;
     foreach my $i (0 .. $#$contents) {                                                          |     foreach my $i (0 .. $#$lines) {
         my($line, $line_with_vars) = ($$contents[$i], $$with_varnames[$i]);                     |         my($line, $line_with_vars) = ($$lines[$i], $$lines_orig[$i]);
         chomp $line_with_vars;                                                                  |         chomp $line_with_vars;
         if ($line =~ /^#line\s+([0-9]+)/) {                                                     |         if ($line =~ /^#line\s+([0-9]+)/) {
             $line_num = $1;                                                                     |             $line_num = $1;
             next;                                                                               |             next;
         }                                                                                       |         }
         push @contents, {'line', $line_num, 'key', munge_line($line), 'code', $line_with_vars}; |         push @contents, {'line', $line_num, 'key', munge_line($line), 'code', $line_with_vars};
         ++$line_num;                                                                            |         ++$line_num;
     }                                                                                           |     }
     return postfilter(\@contents);                                                              |     return postfilter(\@contents);
 }                                                                                               | }
