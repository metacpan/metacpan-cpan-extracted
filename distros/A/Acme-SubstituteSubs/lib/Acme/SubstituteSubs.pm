package Acme::SubstituteSubs;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.02';

=head1 NAME

Acme::SubstituteSubs - Replace subroutines at run-time

=head1 SYNOPSIS

    use Acme::SubstituteSubs;

    sub say_hi { print "hihihihi!\n"; }

    my $say_hi = Acme::SubstituteSubs->get('main::say_hi') or die;
    $say_hi =~ s/"hi/"hihi/;
    Acme::SubstituteSubs->set('main::say_hi', $say_hi) or die;
    say_hi();

    exec 'perl', $0;


=head1 DESCRIPTION

Replaces subroutine definitions in the source code, probably for code that edits
itself or lets its user edit it.

=head2 C<< Acme::SubstituteSubs->get($qualified_function_name) >>

Returns the text of the named function straight from the source file.
For the purposes of this module, all code comes from and goes to the top-level C<.pl> file
as indicated by F<FindBin>'s C<$RealScript> value.
Returns nothing if the sub is not found.

=head2 C<< Acme::SubstituteSubs->set($qualified_function_name, $replacement_code) >>

Replaces the copy of the function or method specified by C<$qualified_function_name>
with the code specified in C<$replacement_code> in the source code of the script (see above).
C<set> uses L<B::Deparse> if passed a coderef.

If the function name doesn't already exist, it'll be added to the end of the appropriate package.
If the package doesn't already exist in the source file of the script, it'll be added to the end and
the new function placed after it.

If attempting to replace a function defined elsewhere than the top level C<.pl> file, such as in some module, 
the module won't be changed, but the code will instead be replicated into the main script.
The result is undefined when run from C<perl -e>.

C<die>s if it fails to write and replace the original source file.

=head2 C<< Acme::SubstituteSubs->list() >>

Lists C<namespace::function> combinations available for edit.

=head2 C<< Acme::SubstituteSubs->list_packages() >>

Lists packages defined in the source script.

=head1 TODO/BUGS

=item Needs a REPL plugin, so REPLs can call this when the user redefines a subroutine.

=item Parses the document again each time a method is called rather than caching it.  Bug.

=item There's gotta be a better way to use the PPI API but I just could not get the C<replace> method to work.

=item Should have been called L<Acme::ModifyMethods>?

=item Somehow tie or watch the stash and automatically decompile and write out new subroutines on change?

=item Hardly tested this at all.  I'd wait for 0.02 if I were you.

=head2

=head1 HISTORY

=over 8

=item 0.02

Fixed the example.

=item 0.01

Original version; created by h2xs 1.23 with options

  -A -C -X -b 5.8.0 -c -n Acme::SubstituteSubs --extra-anchovies

=back


=head1 SEE ALSO

=item L<PPI>

=item L<Acme::State>

=item L<Acme::MUD>

=item L<Continuity::Monitor>

If you're using Acme modules, a therapist.

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut

use IO::Handle;
use PPI;
use FindBin '$RealScript';
use Devel::Caller;
use B::Deparse;

sub new { $_[0] }

sub get {
    shift if Devel::Caller::called_as_method;
    my $fqfunc = shift;

    my ($packagename, $methodname) = ($fqfunc =~ m/(.*)::(.*)/, 'main', $fqfunc);
    my $doc = PPI::Document->new($RealScript) or die PPI::Document->errstr;

    my $code;

    my $currentmodule = "main";
    for my $child ($doc->children) {
        if($child->isa('PPI::Statement::Sub')) {
            $code = $child->content if $child->name eq $methodname and $currentmodule eq $packagename;
        } elsif($child->isa('PPI::Statement::Package')) {
            $currentmodule = $child->namespace;
        }
    }

    return unless $code;
    return $code;

}

sub set {
    shift if Devel::Caller::called_as_method;
    my $fqfunc = shift;
    my $code = shift;

    my ($packagename, $methodname) = ($fqfunc =~ m/(.*)::(.*)/, 'main', $fqfunc);

    defined $code or die 'set($qualified_function_name, $replacement_code)';

    # if code is a CODE ref, deparse it
    # XXX extra points for keeping values for lexicals
    $code = B::Deparse->new->coderef2text($code) if ref($code) and ref($code) eq 'CODE';

    if($code =~ m/^{/) {
        $code = qq<sub $code>;  # happens when B::Deparse kicks in
    } elsif($code =~ m/^\s*sub\s+{/) {
        $code =~ s/sub/sub $methodname /;  # untested codepath alert
    } elsif($code !~ m/^\s*sub/) {
        $code = qq<sub $methodname { $code }>;
    }

    # $code .= "\n" unless $code =~ m/\n$/s;

    # STDERR->print("saving updates to $RealScript\n");
    open my $fh, '>', $RealScript.'.new' or die $!;

    my $currentpackage = 'main';
    my $foundit = 0;

    my $doc = PPI::Document->new($RealScript) or die PPI::Document->errstr;

    for my $child ($doc->children) {
        if($child->isa('PPI::Statement::Sub')) {
            if(! $foundit and $child->name eq $methodname and $currentpackage eq $packagename) {
                $fh->print($code); # instead of $child->content
                $foundit = 1;
            } else {
                $fh->print($child->content);
            }
        } elsif($child->isa('PPI::Statement::Package')) {
            if(! $foundit and $currentpackage eq $packagename) {
                $fh->print($code);
                $foundit = 1;
            }
            $currentpackage = $child->namespace;
            $fh->print($child->content);
        } else {
            $fh->print($child->content) or die;
        }
    }
    if(! $foundit ) {
        # at the end of the file and still haven't found the package/sub?  just append it.
        if($currentpackage ne $packagename) {
            $fh->print(qq{\npackage $packagename;\n});
        }
        $fh->print($code);
    }
    $fh->close;

    rename $RealScript, $RealScript.'.last';
    rename $RealScript.'.new', $RealScript or do {
        warn "renaming new pl file into place as ``$RealScript'' failed: $!";
    };
}

sub list_both {
    shift if Devel::Caller::called_as_method;

    my @packages;
    my @subs;

    my $doc = PPI::Document->new($RealScript) or die PPI::Document->errstr;

    my $currentpackage = 'main::';
    push @packages, $currentpackage;
    for my $child ($doc->children) {
        if($child->isa('PPI::Statement::Sub')) {
            push @subs, $currentpackage . $child->name;
        } elsif($child->isa('PPI::Statement::Package')) {
            $currentpackage = $child->namespace . '::';
            push @packages, $currentpackage;
        }
    }

    return \@subs, \@packages;

}

sub list {
    return @{ list_both()->[0] };
}

sub list_packages {
    return @{ list_both()->[1] }; 
}

1;
