package CodeGen::Cpppp::Output;

our $VERSION = '0.003'; # VERSION
# ABSTRACT: Collect text output into named sections

use v5.20;
use warnings;
use experimental 'signatures', 'postderef';
use Carp;
use Scalar::Util 'looks_like_number';
use List::Util 'max';
use overload '""' => sub { $_[0]->get };


our %standard_sections= (
   public => 100,
   protected => 200,
   private => 10000,
);
sub new($class, @args) {
   bless {
      section_priority => { %standard_sections },
      out => {},
      @args == 1 && ref $args[0]? %{$args[0]}
      : !(@args & 1)? @args
      : croak "Expected hashref or even-length list"
   }, $class;
}


sub section_list($self) {
   my $pri= $self->section_priority;
   sort { $pri->{$a} <=> $pri->{$b} } keys %$pri;
}

sub has_section($self, $name) {
   defined $self->section_priority->{$name};
}

sub section_priority($self) {
   $self->{section_priority}
}

sub declare_sections($self, @list) {
   my $pri= $self->section_priority;
   my $max_before_private= max grep $_ < $pri->{private}, values %$pri;
   my $next= $max_before_private + 1;
   while (@list) {
      my $name= shift @list;
      looks_like_number($name) and croak "Expected non-numeric name at '$name'";
      if (looks_like_number($list[0])) {
         $pri->{$name}= shift @list;
      } elsif (!defined $pri->{$name}) {
         $name =~ /\.\.|,/ and croak "Section names may not contain '..' or ','";
         $pri->{$name}= $next++;
      }
   }
   $self;
}


sub append($self, $section, @code) {
   defined $self->{section_priority}{$section} or croak "Unknown section $section";
   push @{$self->{out}{$section}}, @code;
}
sub prepend($self, $section, @code) {
   defined $self->{section_priority}{$section} or croak "Unknown section $section";
   unshift @{$self->{out}{$section}}, @code;
}


sub expand_section_selector($self, @list) {
   @list= map +(ref $_ eq 'ARRAY'? @$_ : $_), @list;
   @list= map split(',', $_), @list;
   my $sec_pri= $self->section_priority;
   my %seen;
   for (@list) {
      if (/([^.]+)\.\.([^.]+)/) {
         my $low= $sec_pri->{$1} // croak "Unknown section $1";
         my $high= $sec_pri->{$2} // croak "Unknown section $2";
         for (keys %$sec_pri) {
            $seen{$_}++ if $sec_pri->{$_} >= $low && $sec_pri->{$_} <= $high;
         }
      } else {
         $sec_pri->{$_} // croak "Unknown section $_";
         $seen{$_}++;
      }
   }
   sort { $sec_pri->{$a} <=> $sec_pri->{$b} } keys %seen;
}


sub get($self, @sections) {
   my @sec= @sections? $self->expand_section_selector(@sections) : $self->section_list;
   join '', map @{$self->{out}{$_} // []}, @sec;
}

sub consume($self, @sections) {
   my @sec= @sections? $self->expand_section_selector(@sections) : $self->section_list;
   my $out= join '', map @{delete $self->{out}{$_} // []}, @sec;
   @{$self->{out}{$_}}= () for @sec;
   $out
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CodeGen::Cpppp::Output - Collect text output into named sections

=head1 DESCRIPTION

C code usually needs generated in different parts, like a public header,
private-to-the-project header, the forward declarations of static function,
and finally the function definitions themselves.
This object encapsulates that concept by storing different "sections" of
generated code that you can later direct to the files where they need to go.

The default sections are:

=over

=item public

Lines of code for the public header.  Maybe also inline functions.
C<priority=100>

=item protected

Lines of code for consumption by other related modules, exposing more data
structures and macros than are appropriate for the public header.
C<priority=200>

=item private

The implementation of the compilation unit, and declarations of things that
will only affect this compilation unit.
C<priority=10000>

=back

You can append or prepend blocks of code to any of these sections, or define
additional sections of your own.  The sections you define should be assigned
a C<priority> to help sort them into the list above.  You may use floating
point numbers.

=head1 METHODS

=head2 new

Standard constructor, accpeting key/val list or hashref.

=head2 declare_sections

  $out->declare_sections($name1, $name2, ...);
  $out->declare_sections($name1 => $priority, $name2 => ..);

Declare one or more new sections.  If you omit the priority values, they will
be automatically selected counting upward from the last section before C<'private'>.

=head2 section_priority

A hashref of C<< { $section_name => $priority } >>.

=head2 section_list

Returns a list of output section names, in the order that they would need
compiled.

=head2 append

  $out->append($section, @code_block);

Add one or more blocks of code to the end of the named section.
The section must be declared.

=head2 prepend

  $out->prepend($section, @code_block);

Add one or more blocks of code to the beginning of the named section.
The section must be declared.

=head2 expand_section_selector

Expands the following patterns:

  'public', ['protected']  =>  ( 'public', 'protected' )
  "public,private"         =>  ( 'public', 'private' )
  "public..private"        =>  ( 'public', 'protected', 'private' )

returning the list in priority order.

=head2 get

  $all= $out->get;
  $header= $out->get('public','protected');
  $unit= $out->get('protected..private');

Collect the output from all or specified sections.  An empty list returns all
sections.  The special notation '..' returns a range of sections, inclusive.

=head2 consume

Same as L</get> but removes the content it returns.  The sections remain
defined, but empty.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.003

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
