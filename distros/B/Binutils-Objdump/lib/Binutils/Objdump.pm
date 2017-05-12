#
# Copyright (c) 2009, 2011  Slade Maurer, Alexander Sviridenko
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
package Binutils::Objdump;

our $VERSION = '0.1.2';

our @ISA = qw(Exporter);
our @EXPORT = qw(objdump objdumpopt objdumpwrap);
our @EXPORT_OK = qw(objdump objdumpopt objdumppath objdumpwrap 
		    objdump_dynamic_reloc_info objdump_symtab
		    objdump_section_headers objdump_dynamic_symtab
		    objdump_sec_contents objdump_sec_disasm
    );
our %EXPORT_TAGS = (
    ALL => [qw(objdump objdumpopt objdumppath objdumpwrap 
	       objdump_dynamic_reloc_info objdump_symtab objdump_section_headers
	       objdump_dynamic_symtab objdump_sec_contents objdump_sec_disasm)],
    );

use strict;
use warnings;

# Constants
use constant DEF_WRAPPER => 0; # default wrapper
use constant USR_WRAPPER => 1; # user's wrapper

# By default, if none of object files will not be set,
# will be used object file with such name.
our $default_objfile = 'a.out';

# Try to define the path for objdump automatically. Also can be changed by user.
if (($^O =~ /MSWin/) or ($^O eq "Windows NT")) {
}
# Use `which' on linux.
elsif ($^O =~ /linux/) {
    my $path = `which objdump`;
    chomp $path;
    objdumppath($path);
}

# Information.
our %objdumpinfo = ();

sub __objdumpinfo
{
    my ($id, @lines) = (shift, @_);
    my $ref = \%objdumpinfo;
    for (1..scalar(@$id)) {
        if ($_ < scalar(@$id)) {
            $ref->{$id->[$_-1]} = {}
	    if !defined $ref->{$id->[$_-1]};
            $ref = $ref->{$id->[$_-1]};
        } else {
            $ref->{$id->[$_-1]} = \@lines;
        }
    }
}

# The labels and their wrappers, that will be used during
# parsing process.
our %objdumpwrappers = (
    # Dynamic symbol table
    'DYNAMIC SYMBOL TABLE:'               => [sub { __objdumpinfo(['dynamic symbol table'        ] , @_) }], # -T
    # The summary information from the section headers of the object file
    'Sections:'                           => [sub { __objdumpinfo(['sections'                    ] , @_) }], # -h
    # The symbol table entries of the file
    'SYMBOL TABLE:'                       => [sub { __objdumpinfo(['symbol table'                ] , @_) }], # -t
    # The dynamic relocation entries of the file
    'DYNAMIC RELOCATION RECORDS:'         => [sub { __objdumpinfo(['dynamic relocation records'  ] , @_) }], # -R
    # Dump contents of section...
    'Contents of section .interp'         => [sub { __objdumpinfo(['contents' , '.interp'        ] , @_) }],
    'Contents of section .note.ABI-tag'   => [sub { __objdumpinfo(['contents' , '.note.ABI-tag'  ] , @_) }],
    'Contents of section .hash'           => [sub { __objdumpinfo(['contents' , '.hash'          ] , @_) }],
    'Contents of section .gnu.hash'       => [sub { __objdumpinfo(['contents' , '.gnu.hash'      ] , @_) }],
    'Contents of section .dynsym'         => [sub { __objdumpinfo(['contents' , '.dynsym'        ] , @_) }],
    'Contents of section .dynstr'         => [sub { __objdumpinfo(['contents' , '.dynstr'        ] , @_) }],
    'Contents of section .gnu.version'    => [sub { __objdumpinfo(['contents' , '.gnu.version'   ] , @_) }],
    'Contents of section .gnu.version_r'  => [sub { __objdumpinfo(['contents' , '.gnu.version_r' ] , @_) }],
    'Contents of section .rel.dyn'        => [sub { __objdumpinfo(['contents' , '.rel.dyn'       ] , @_) }],
    'Contents of section .rel.plt'        => [sub { __objdumpinfo(['contents' , '.rel.plt'       ] , @_) }],
    'Contents of section .init'           => [sub { __objdumpinfo(['contents' , '.init'          ] , @_) }],
    'Contents of section .plt'            => [sub { __objdumpinfo(['contents' , '.plt'           ] , @_) }],
    'Contents of section .text'           => [sub { __objdumpinfo(['contents' , '.text'          ] , @_) }],
    'Contents of section .fini'           => [sub { __objdumpinfo(['contents' , '.fini'          ] , @_) }],
    'Contents of section .rodata'         => [sub { __objdumpinfo(['contents' , '.rodata'        ] , @_) }],
    'Contents of section .eh_frame_hdr'   => [sub { __objdumpinfo(['contents' , '.eh_frame_hdr'  ] , @_) }],
    'Contents of section .eh_frame'       => [sub { __objdumpinfo(['contents' , '.eh_frame'      ] , @_) }],
    'Contents of section .ctors'          => [sub { __objdumpinfo(['contents' , '.ctors'         ] , @_) }],
    'Contents of section .dtors'          => [sub { __objdumpinfo(['contents' , '.dtors'         ] , @_) }],
    'Contents of section .jcr'            => [sub { __objdumpinfo(['contents' , '.jcr'           ] , @_) }],
    'Contents of section .dynamic'        => [sub { __objdumpinfo(['contents' , '.dynamic'       ] , @_) }],
    'Contents of section .got'            => [sub { __objdumpinfo(['contents' , '.got'           ] , @_) }],
    'Contents of section .got.plt'        => [sub { __objdumpinfo(['contents' , '.got.plt'       ] , @_) }],
    'Contents of section .data'           => [sub { __objdumpinfo(['contents' , '.data'          ] , @_) }],
    'Contents of section .comment'        => [sub { __objdumpinfo(['contents' , '.comment'       ] , @_) }],
    'Contents of section .debug_aranges'  => [sub { __objdumpinfo(['contents' , '.debug_aranges' ] , @_) }],
    'Contents of section .debug_pubnames' => [sub { __objdumpinfo(['contents' , '.debug_pubnames'] , @_) }],
    'Contents of section .debug_info'     => [sub { __objdumpinfo(['contents' , '.debug_info'    ] , @_) }],
    'Contents of section .debug_abbrev'   => [sub { __objdumpinfo(['contents' , '.debug_abbrev'  ] , @_) }],
    'Contents of section .debug_line'     => [sub { __objdumpinfo(['contents' , '.debug_line'    ] , @_) }],
    'Contents of section .debug_str'      => [sub { __objdumpinfo(['contents' , '.debug_str'     ] , @_) }],
    'Contents of section .debug_ranges'   => [sub { __objdumpinfo(['contents' , '.debug_ranges'  ] , @_) }],
    # Disassembly of section...
    'Disassembly of section .text'        => [sub { __objdumpinfo(['disassembly' , '.text'] , @_) }],
    'Disassembly of section .plt'         => [sub { __objdumpinfo(['disassembly' , '.plt' ] , @_) }],
    'Disassembly of section .init'        => [sub { __objdumpinfo(['disassembly' , '.init'] , @_) }],
    'Disassembly of section .fini'        => [sub { __objdumpinfo(['disassembly' , '.fini'] , @_) }],
);

sub objdumpwrap ($$)
{
    my ($label, $wrapper) = (shift, shift);
    if (ref($wrapper) eq 'CODE') {
	# Try to find out, if such label (but, maybe, not exactly the same) 
	# already exist.
        foreach (keys %objdumpwrappers) {
	    $label = $_
		if (/^\s*$label\s*(\:)?\s*$/);
        }
	# Set a second wrapper by user.
        $objdumpwrappers{$label}->[USR_WRAPPER] = $wrapper;
    }
}

# The path to the objdump. 
our $objdumppath;

sub objdumppath
{
    if (scalar(@_)) {
        $objdumppath = shift;
    }
    return $objdumppath;
}

# The string with options for objdump.
my $objdumpoptstr;

sub objdumpopt
{
    # If none options defined, then return current string of options
    if (!scalar(@_)) {
        return $objdumpoptstr || "";
    }
    # Form new string of options.
    $objdumpoptstr = "";
    foreach (@_) {
        $objdumpoptstr = join " ", $objdumpoptstr, split(/\s/, $_);
    }
}

sub objdump
{
    my @objfiles = @_;
    # Update information.
    %objdumpinfo = ();

    # If objdump cannot be found, then print an
    # error message and die.
    if (!-e objdumppath() || !-f objdumppath()) {
        die "Objdump '". objdumppath() ."' cannot be found.\n";
    }

    # If object files was not set, use default object file.
    if (!scalar(@objfiles)) {
        push @objfiles, $default_objfile;
    }

    my @infos = ();
    foreach my $objfile (@objfiles) {
        my $cmd = join(' ', objdumppath(), objdumpopt(), $objfile, '2>&1');
	my $info = `$cmd`;

        my @lines = split /\n/, $info;

        my @buff = ();
        my %passed_labels = ();
        my $label;
        my $wrappers;

      LINE: while (scalar(@lines)) {
          my $line = shift @lines;
          do {
              foreach (keys %objdumpwrappers) {
                  next if defined $passed_labels{$_};
                  if ($line =~/$_/) {
                      do { for (@$wrappers) { $_->(@buff) if defined $_ } } if defined $wrappers;
                      @buff = ();
                      ($label, $wrappers) = ($_, $objdumpwrappers{$_});
                      $passed_labels{$label}++;
                      next LINE;
                  }
              }
          } if (scalar(keys %passed_labels) < scalar(keys %objdumpwrappers));
          push @buff, $line;
        }
        # Run the last wrapper if such defined...
        do { for (@$wrappers) { $_->(@buff) if defined $_ } } if defined $wrappers;

	push @infos, $info;
    }

    return @infos;
}

sub objdump_dynamic_reloc_info { if (defined (my $lines = $objdumpinfo{'dynamic relocation records'})) { return @$lines } }
sub objdump_symtab { if (defined (my $lines = $objdumpinfo{'symbol table'})) { return @$lines } }
sub objdump_section_headers { if (defined (my $lines = $objdumpinfo{'sections'})) { return @$lines } }
sub objdump_dynamic_symtab { if (defined (my $lines = $objdumpinfo{'dynamic symbol table'})) { return @$lines } }
sub objdump_sec_contents { if (defined $_[0] && defined (my $lines = $objdumpinfo{'contents'}->{$_[0]})) { return @$lines } }
sub objdump_sec_disasm { if (defined $_[0] && defined (my $lines = $objdumpinfo{'disassembly'}->{$_[0]})) { return @$lines } }

1;

__END__

=head1 NAME

Binutils::Objdump - Perl interface to Binutils objdump

=head1 SYNOPSIS

    use Binutils::Objdump;

    # Standard using of objdump. Print the whole information.
    objdumpopt(@ARGV);
    print objdump();

    # Now for the block 'SYMBOL TABLE', will be called 
    # mysymtab subroutine, which will get all lines for this block.
    sub mysymtab {
        print "SymTab:\n";
        print join "\n", @_;
    }
    objdumpwrap("SYMBOL TABLE" => \&mysymtab);
    objdump();

=head1 DESCRIPTION

I<objdump> displays  information  about  one or more object files. The options
control what particular information to display. This information is mostly 
useful to programmers who are working on the compilation tools, as opposed to
programmers who just want their program to compile and work.

This module provides wrappers for the objdump output information parts,
specified by special labels. To each part correspond a special wrapper, which
can be extended by your own.

The script C<odasm> is an example of disassembler based on L<Binutils::Objdump>
module.

=head2 Functions

=over

=item B<objdumppath([$path])>

Sets the new path to objdump if C<$path> defined. Returns current path to the
objdump executeable file. By default this path will be defined automatically,
but if you have another location for it, you may change it.

=item B<objdumpopt([$optstr])>

Builds a new string of options if C<$optstr> defined. Returns options for
objdump in string format. 

For example, options can be taken from C<@ARGV>.

=item B<objdump([@objfules])>

Executes C<objdump> with string of options C<objdumpopt()> and  object files
C<@objfiles>, that have to be examinated. Returns the whole information about
one or more object files.
 
By default, if none of object files will not be set, will be used default object
file I<a.out> from the current location.

=item B<objdumpwrap($label, \&wrapper)>

Defines a special wrapper C<\&wrapper> for the correspond label C<LABEL>.
Notice, that default wrapper will not be replaced, and so, can be used.

When a label appears, the following lines will be saved till the next matched
label. Then this lines will be passed to appropriate wrappers. Be carefull with
default labels (if some label includes another, they will be merged).

=item B<objdump_dynamic_symtab()>

Default wrapper for dynamic symbol table. Returns lines.

=item B<objdump_section_headers()>

Default wrapper for summary information from the section headers of the object file. 
Returns lines.

=item B<objdump_symtab()>

Default wrapper for symbol table entries of the file. Returns lines.

=item B<objdump_dynamic_reloc_info()>

Default wrapper for dynamic relocation entries of the file. Returns lines.

=item B<objdump_sec_contents($section)>

Default wrapper for contents of section C<$section>. Returns lines for
correspond section.

=item B<objdump_sec_disasm($section)>

Default wrapper for disassembly of section C<$section>. Returns lines for
correspond section.

=back

=head2 Exports

By default will be exported C<objdump>, C<objdumpopt> and C<objdumpwrap>. The
following tags can be used to selectively import functions defined in this
module:

    :ALL    objdump() objdumpopt() objdumppath() objdumpwrap() 
            objdump_dynamic_reloc_info() objdump_symtab() objdump_section_headers() 
            objdump_dynamic_symtab() objdump_sec_contents() objdump_sec_disasm()

=head1 AUTHORS

Alexander Sviridenko, E<lt>oleks.sviridenko@gmail.comE<gt>

Slade Maurer, E<lt>slade@computer.orgE<gt>

=head1 COPYRIGHT

The Binutils::Objdump module is Copyright (c) 2009, 2011 Slade Maurer,
Alexander Sviridenko. All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl 5.10.0 README file.

=cut
