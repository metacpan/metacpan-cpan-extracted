package Alien::Jerl;
use strict;

require Exporter;
use base qw[Exporter];
use vars qw[$VERSION @EXPORT %EXPORT_TAGS];

$VERSION     = '1.11';
@EXPORT      = qw[jerlVersion alienJerlVersion jerlMissingJVMMessage jerlOneLiner];
%EXPORT_TAGS = ( ':all' => \@EXPORT );

sub jerlMissingJVMMessage {
   return 'could not execute java -jar lib/Alien/jerl.jar -v';
}

sub jerlVersion {
  
    my $jarVersion = `java -jar lib/Alien/jerl.jar -v` || jerlMissingJVMMessage();
    
    return $jarVersion;    

}

sub jerlOneLiner {

    my $oneLineProgram = shift;

    # if there's no param, then do not run it, just return empty
    if (!$oneLineProgram) {
	print STDERR "[Warning] jerlOneLiner was empty or did not contain a program";
	return '';
    }

    my $output = `java -jar lib/Alien/jerl.jar -e '$oneLineProgram'` || '';
    
    return $output    

}



sub alienJerlVersion {
    
    return $VERSION;
}

1;

__END__

=head1 NAME

Alien::Jerl - micro perl running on JVM (MIPS Interpreter)

=head1 SYNOPSIS

 java -jar ./lib/alien/jerl.jar --help 

 java -jar ./lib/alien/jerl.jar ./perl/fib.pl 

=head1 DESCRIPTION

=head2 Introduction

Jerl allows perl to run within the JVM (not having to access any external libs).

=head2 Details

Jerl allows perl to run within the JVM (not having to access any external libs). Perl has been virtualized to run within the JVM. The current implementation is a version of microperl. 

=head1 FAQ

     https://code.google.com/p/jerl/wiki/JERL_FAQ

=head2 Why

    Jerl's purpose is merely to pull Perl into Java (no JNI/native Perl)
    Fun
    Not speed (see Inline::Java in Alternatives Below)
    Use Perl from a Jar 

=head2 Why nestedVM / MIPS

    nestedVM provided a straightforward means of recompilation
    MIPS running within Java is not fast, but there are alternatives for Perl Java integration if speed is a concern(see below)
    Implement project in a maintainable way so updates are not too time consuming 

=head2 Isn't there something like this already

    For speed / optimization Inline::Java works
    Check CPAN.org, search Java (there may be something similar)
    Goto Perlmonks.org, search Java (there may be something similar) 

=head2 Jerl Alternatives (TIMTOWTDI)

    Perl's interface to JAVA Inline::Java
    --> http://search.cpan.org/search?mode=module&query=Inline::Java
    JPL: A deprecated means of accessing JAVA & Perl
    --> http://search.cpan.org/~gmpassos/PLJava-0.04/README.pod 

=head2 What Jars are required

    jerl.jar is required for jerl
    jerl_perlVM.jar is a wapper for interfacing with jerl via Java
    you may find both in the eclipse sample project 

=head1 PROJECT SITE
     
     http://code.google.com/p/jerl/

=head2 C<jerlVersion()>

C<jerlVersion()> returns the current version of jerl from the Jar and of this package (multi line)

=head2 C<jerlOneLiner( String )>

C<jerlOneLiner( String )> Returns the output of a single line program which is passed in as an argument

=over 4

=item JVM

A working JVM must be available for this to work properly

=back

=head1 AUTHOR

Michaelt Shomsky  <F<17michaelt@gmail.com>>

=head1 COPYRIGHT

Copyright (c) 2013 Michael Shomsky, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5 or, at your option, any later version of Perl you may have available (perl and glue code).

The Java library is covered by the GNU Lesser General Public License:

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA or download it from http://www.gnu.org/licenses/lgpl.html

=cut
