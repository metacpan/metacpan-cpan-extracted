# Copyright 2015 MailerMailer, LLC - http://www.mailermailer.com
#
# Based in large part on the CSS::Tiny CPAN Module
# http://search.cpan.org/~adamk/CSS-Tiny/
#
# This is version 2 of this module, which concerns itself with very strictly preserving ordering of rules,
# something that has been the focus of this module series from the beginning. We focus more on preservation
# of rule ordering than we do on ease of modifying enclosed rules. If you are attempting to modify 
# rules through an API please see CSS::Simple

package CSS::Inliner::Parser;

use strict;
use warnings;

use Carp;

use Storable qw(dclone);

=pod

=head1 NAME

CSS::Inliner::Parser - Interface through which to read/write CSS files while respecting the cascade order

NOTE: This sub-module very seriously focuses on respecting cascade order. As such this module is not for you
      if you want to modified a stylesheet once it's read. If you are looking for that functionality you may
      want to look at the sister module, CSS::Simple

=head1 SYNOPSIS

 use CSS::Inliner::Parser;

 my $css = new CSS::Inliner::Parser();

 $css->read({ filename => 'input.css' });

 #perform manipulations...

 $css->write({ filename => 'output.css' });

=head1 DESCRIPTION

Class for reading and writing CSS. Unlike other CSS classes on CPAN this particular module
focuses on respecting the order of selectors. This is very useful for things like... inlining
CSS, or for similar "strict" CSS work.

=cut

BEGIN {
  my $members = ['ordered','stylesheet','warns_as_errors','content_warnings'];

  #generate all the getter/setter we need
  foreach my $member (@{$members}) {
    no strict 'refs';                                                                                

    *{'_' . $member} = sub {
      my ($self,$value) = @_;

      $self->_check_object();

      $self->{$member} = $value if defined($value);

      return $self->{$member};
    }
  }
}


=pod

=head1 CONSTRUCTOR

=over 4

=item new ([ OPTIONS ])

Instantiates the CSS::Inliner::Parser object. Sets up class variables that are used during file parsing/processing.

B<warns_as_errors> (optional). Boolean value to indicate whether fatal errors should occur during parse failures.

=back

=cut

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $rules = [];
  my $selectors = {};

  my $self = {
              stylesheet => undef,
              ordered => $rules,
              selectors => $selectors,
              content_warnings => undef,
              warns_as_errors => (defined($$params{warns_as_errors}) && $$params{warns_as_errors}) ? 1 : 0
             };

  bless $self, $class;
  return $self;
}

=head1 METHODS

=cut

=pod

=over 4

=item read_file( params )

Opens and reads a CSS file, then subsequently performs the parsing of the CSS file
necessary for later manipulation.

This method requires you to pass in a params hash that contains a
filename argument. For example:

$self->read_file({ filename => 'myfile.css' });

=cut

sub read_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{filename}) {
    croak "You must pass in hash params that contain a filename argument";
  }

  open FILE, "<", $$params{filename} or croak $!;
  my $css = do { local( $/ ) ; <FILE> } ;

  $self->read({ css => $css });

  return();
}

=pod

=item read( params )

Reads css data and parses it. The intermediate data is stored in class variables.

Compound selectors (i.e. "a, span") are split apart during parsing and stored
separately, so the output of any given stylesheet may not match the output 100%, but the 
rules themselves should apply as expected.

This method requires you to pass in a params hash that contains scalar
css data. For example:

$self->read({ css => $css });

=cut

sub read {
  my ($self,$params) = @_;

  $self->_check_object();

  $self->_content_warnings({}); # overwrite any existing warnings

  unless (exists $$params{css}) {
    croak 'You must pass in hash params that contains the css data';
  }

  if ($params && $$params{css}) {
    # Flatten whitespace and remove /* comment */ style comments
    my $string = $$params{css};
    $string =~ tr/\n\t/  /;
    $string =~ s!/\*.*?\*\/!!g;

    # Split into styles
    my @tokens = grep { /\S/ } (split /(?<=\})/, $string);
    while (my $token = shift @tokens) {
      if ($token =~ /^\s*@[\w-]+\s+(?:url\()?"/) {
        # simple at-rules consisting of a rule name and prelude, but no block - we have to jump through some
        # hoops as we can accidentally capture multi-line rules here. If such a thing happens we capture
        # any inadvertently trapped content and push it back for parsing later
        
        my $atrule = $token;
        
        $atrule =~ /^\s*(@[\w-]+)\s*((?:url\()?"[^;]*;)(.*)/;
        
        $self->add_at_rule({ type => $1, prelude => $2, block => undef });
        
        unshift(@tokens, $3);
      }
      elsif ($token =~ /^\s*(\@[\w-]+)\s+{\s*([^{]*)}$/) {
        # multiline at-rules without a prelude, nothing to protect here

        $self->add_at_rule({ type => $1, prelude => undef, block => $2 });
      }
      elsif ($token =~ /^\s*\@/) {
        # multiline at-rules with a prelude, nothing to protect here

        my $atrule = $token;

        for (my $attoken = shift(@tokens); defined($attoken); $attoken = shift(@tokens)) {
          if ($attoken !~ /^\s*\}\s*$/) {
            $atrule .= "\n$attoken\n";
          }
          else {
            last;
          }
        }

        $atrule =~ /^\s*(@[\w-]+)\s*([^{]*){\s*(.*?})$/s;

        $self->add_at_rule({ type => $1, prelude => $2, block => $3 });
      }
      elsif ($token =~ /^\s*([^{]+?)\s*{\s*(.*)}\s*$/) {
        # Split in such a way as to support grouped styles

        my $rule = $1;
        my $props = $2;

        $rule =~ s/\s{2,}/ /g;

        # Split into properties
        my $properties = {};
        foreach (grep { /\S/ } split /\;/, $props) {
          # skip over browser specific properties
          if ((/^\s*[\*\-\_]/) || (/\\/)) {
            next; 
          }

          # check if properties are valid, reporting error as configured        
          unless (/^\s*([\w._-]+)\s*:\s*(.*?)\s*$/) {
            $self->_report_warning({ info => "Invalid or unexpected property '$_' in style '$rule'" });
            next;
          }

          #store the property for later
          $$properties{lc $1} = $2;
        }

        my @selectors = split /,/, $rule; # break the rule into the component selector(s)

        #apply the found rules to each selector
        foreach my $selector (@selectors) {
          $selector =~ s/^\s+|\s+$//g;

          $self->add_qualified_rule({ selector => $selector, declarations => $properties });
        }
      }
      else {
        $self->_report_warning({ info => "Invalid or unexpected style data '$_'" });
      }
    }
  }
  else {
    $self->_report_warning({ info => 'No stylesheet data was found in the document'});
  }

  return();
}

=pod

=item write_file()

Write the parsed and manipulated CSS out to a file parameter

This method requires you to pass in a params hash that contains a
filename argument. For example:

$self->write_file({ filename => 'myfile.css' });

=cut

sub write_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless (exists $$params{filename}) {
    croak "No filename specified for write operation";
  }

  # Write the file
  open( CSS, '>'. $$params{filename} ) or croak "Failed to open file '$$params{filename}' for writing: $!";
  print CSS $self->write();
  close( CSS );

  return();
}

=pod

=item write()

Write the parsed and manipulated CSS out to a scalar and return it

This code makes some assumptions about the nature of the prelude and data portions of the stored css rules
and possibly is insufficient.

=cut

sub write {
  my ($self,$params) = @_;

  $self->_check_object();

  my $contents = '';

  foreach my $rule ( @{$self->_ordered()} ) {
    if ($$rule{selector} && $$rule{declarations}) {
      #grab the properties that make up this particular selector
      my $selector = $$rule{selector};
      my $declarations = $$rule{declarations};

      $contents .= "$selector {\n";
      foreach my $property ( sort keys %{ $declarations } ) {
        $contents .= "  " . lc($property) . ": ".$$declarations{$property}. ";\n";
      }
      $contents .= "}\n";
    }
    elsif ($$rule{type} && $$rule{prelude} && $$rule{block}) {
      $$rule{block} =~ s/([;{])\s*([^;{])/$1\n$2/mg; # attempt to restrict whitespace
      $$rule{block} =~ s/^\s+|\s+$//mg;
      $$rule{block} =~ s/[^\S\r\n]+/ /mg;
      $$rule{block} =~ s/^([\w-]+:)/  $1/mg;
      $$rule{block} =~ s/^/  /mg;

      $contents .= $$rule{type} . " " . $$rule{prelude}  . "{\n" . $$rule{block} . "\n}\n";
    }
    elsif ($$rule{type} && $$rule{prelude}) {
      $contents .= $$rule{type} . " " . $$rule{prelude} . "\n";
    }
    elsif ($$rule{type} && $$rule{block}) {
      $$rule{block} =~ s/;\s*([\w-]+)/;\n$1/mg; # attempt to restrict whitespace
      $$rule{block} =~ s/^\s+|\s+$//mg;
      $$rule{block} =~ s/[^\S\r\n]+/ /mg;
      $$rule{block} =~ s/([\w-]+:)/  $1/mg;

      $contents .= $$rule{type} . " {\n" . $$rule{block} . "\n}\n";
    }
    else {
      $self->_report_warning({ info => "Invalid or unexpected rule encountered while writing out stylesheet" });
    }
  }

  return $contents;
}

=pod
    
=item content_warnings()
 
Return back any warnings thrown while parsing a given block of css

Note: content warnings are initialized at read time. In order to 
receive back content feedback you must perform read() first.

=cut

sub content_warnings {
  my ($self,$params) = @_;

  $self->_check_object();

  my @content_warnings = keys %{$self->_content_warnings()};

  return \@content_warnings;
}

####################################################################
#                                                                  #
# The following are all get/set methods for manipulating the       #
# stored stylesheet                                                #
#                                                                  #
####################################################################

=pod

=item get_rules( params )

Get an array of rules representing the composition of the stylesheet. These rules
are returned in the exact order that they were discovered. Both qualified and at
rules are returned by this method. It is left to the caller to pull out the kinds of
rules your application needs to accomplish your goals.

The structures returned match up with the fields set while adding the rules via the add_x_rule collection methods.

Specifically at-rules will contain a type, prelude and block while qualified rules will contain a selector and declarations.

=cut

sub get_rules {
  my ($self,$params) = @_;

  $self->_check_object();

  return $self->_ordered();
}

=pod

=item add_qualified_rule( params )

Add a qualified CSS rule to the ruleset store.

The most common type of CSS rule is a qualified rule. This term became more prominent with the rise of CSS3, but is still
relevant when handling earlier versions of the standard. These rules have a prelude consisting of a CSS selector, along
with a data block consisting of various rule declarations.

Adding a qualified rule is trivial, for example:
$self->add_qualified_rule({ selector => 'p > a', block => 'color: blue;' });

=cut

sub add_qualified_rule {
  my ($self,$params) = @_;

  $self->_check_object();

  my $rule;
  if (exists $$params{selector} && exists $$params{declarations}) { 
    $rule = { selector => $$params{selector}, declarations => $$params{declarations} };

    push @{$self->_ordered()}, $rule;
  }
  else {
    $self->_report_warning({ info => "Invalid or unexpected data '$_' encountered while trying to add stylesheet rule" });
  }

  return $rule;
}

=pod

=item add_at_rule( params )

Add an at-rule to the ruleset store.

The less common variants of CSS rules are know as at-rules. These rules implement various behaviours through various expressions
containing a rule type, prelude and associated data block. The standard is evolving here, so it is not easy to enumerate such
examples, but these rules always start with @.

At rules are a little more complex, an example:
$self->add_at_rule({ type => '@media', prelude => 'print', block => 'body { font-size: 10pt; }' });

=cut

sub add_at_rule {
  my ($self,$params) = @_;

  $self->_check_object();

  my $rule;
  if (exists $$params{type} && exists $$params{prelude} && exists $$params{block}) {
    $rule = { type => $$params{type}, prelude => $$params{prelude}, block => $$params{block} };
    
    push @{$self->_ordered()}, $rule;
  }
  else {
    $self->_report_warning({ info => "Invalid or unexpected data '$_' encountered while trying to add stylesheet rule" });
  }

  return $rule;
}

####################################################################
#                                                                  #
# The following are all private methods and are not for normal use #
# I am working to finalize the get/set methods to make them public #
#                                                                  #
####################################################################

sub _check_object {
  my ($self,$params) = @_;

  unless ($self && ref $self) {
    croak "You must instantiate this class in order to properly use it";
  }

  return();
}

sub _report_warning {
  my ($self,$params) = @_;

  $self->_check_object();

  if ($self->{warns_as_errors}) {
    croak $$params{info};
  }
  else {
    my $warnings = $self->_content_warnings();
    $$warnings{$$params{info}} = 1;
  }

  return();
}

1;

=pod

=back

=head1 Sponsor

This code has been developed under sponsorship of MailerMailer LLC, http://www.mailermailer.com/

=head1 AUTHOR

Kevin Kamel <C<kamelkev@mailermailer.com>>

=head1 ATTRIBUTION

This module is directly based off of Adam Kennedy's <adamk@cpan.org> CSS::Tiny module.

This particular version differs in terms of interface and the ultimate ordering of the CSS.

=head1 LICENSE

This module is a derived version of Adam Kennedy's CSS::Tiny Module.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
