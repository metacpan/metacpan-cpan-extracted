#    Copyright (c) 2011 Raphaël Pinson.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
#    02110-1301 USA

package Config::Augeas::Validator;

use strict;
use warnings;
use base qw(Class::Accessor);
use Config::Augeas qw(get count_match print);
use Config::IniFiles;
use File::Find;
use Term::ANSIColor;

our $VERSION = '1.300';

# Constants from Augeas' internal.h
use constant AUGEAS_META_TREE   => "/augeas";
use constant AUGEAS_SPAN_OPTION => AUGEAS_META_TREE."/span";
use constant AUGEAS_ENABLE      => "enable";
use constant AUGEAS_DISABLE     => "disable";

# Our constants
use constant DEFAULT_RULESDIR => "/etc/augeas-validator/rules.d";

use constant {
   CONF_DEFAULT_SECTION => "DEFAULT",
   CONF_ERR_CODE        => "err_code",
   CONF_WARN_CODE       => "warn_code",
   CONF_LENS            => "lens",
   CONF_PATTERN         => "pattern",
   CONF_EXCLUDE         => "exclude",
   CONF_TAGS            => "tags",
   CONF_LEVEL_ERR       => "error",
   CONF_LEVEL_WARN      => "warning",
   CONF_LEVEL_IGNORE    => "ignore",
   CONF_TYPE_NAME       => "name",
   CONF_TYPE_TYPE       => "type",
   CONF_TYPE_COUNT      => "count",
   CONF_TYPE_EXPR       => "expr",
   CONF_TYPE_VALUE      => "value",
   CONF_TYPE_EXPL       => "explanation",
   CONF_TYPE_LEVEL      => "level",
};
 

# Output
use constant {
   COLOR_INFO           => "blue bold",
   COLOR_VERBOSE        => "blue bold",
   COLOR_OK             => "green bold",
   COLOR_ERR            => "red bold",
   COLOR_WARN           => "yellow bold",
   COLOR_DEBUG          => "blue",
   MSG_ERR              => "E",
   MSG_WARN             => "W",
   MSG_INFO             => "I",
   MSG_VERBOSE          => "V",
   MSG_DEBUG            => "D",
};


sub new {
   my $class = shift;
   my %options = @_;

   my $self = __PACKAGE__->SUPER::new();

   $self->{conffile} = $options{conf};
   $self->{rulesdir} = $options{rulesdir};
   $self->{rulesdir} ||= DEFAULT_RULESDIR;

   $self->{verbose} = $options{verbose};
   $self->{debug} = $options{debug};
   $self->{quiet} = $options{quiet};
   $self->{verbose} = 1 if $self->{debug};

   $self->{recurse} = $options{recurse};

   $self->{nofail} = $options{nofail};

   $self->{exclude} = $options{exclude};

   $self->{tags} = $options{tags};
   $self->{tags} ||= [];

   # System mode off by default
   $self->{syswide} = 0;

   # Init hourglass
   $self->{tick} = 0;

   unless ($self->{conffile}) {
      assert_notempty('rulesdir', $self->{rulesdir});
   }

   $self->{aug} = Config::Augeas->new( "no_load" => 1, enable_span => 1 );

   # Instantiate general error
   $self->{err} = 0;

   return $self;
}

sub load_conf {
   my ($self, $conffile) = @_;

   $self->debug_msg("Loading rule file $conffile");

   $self->{cfg} = new Config::IniFiles( -file => $conffile );
   die MSG_ERR.":[$conffile]: Section ".CONF_DEFAULT_SECTION." does not exist.\n"
      unless $self->{cfg}->SectionExists(CONF_DEFAULT_SECTION);
}


sub init_augeas {
   my ($self) = @_;

   # Initialize Augeas
   $self->{lens} = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_LENS);
   assert_notempty('lens', $self->{lens});

   if ($self->{syswide} != 1) {
      $self->{aug}->rm(AUGEAS_META_TREE."/load/*[label() != \"$self->{lens}\"]");
   }
}

sub play_one {
   my ($self, @files) = @_;

   # Get rules
   @{$self->{rules}} = grep { !/DEFAULT/ } $self->{cfg}->Sections;

   # Get return error code
   $self->{err_code} = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_ERR_CODE) || 1;
   $self->{warn_code} = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_WARN_CODE) || 2;

   $self->init_augeas;

   for my $file (@files) {
      unless (-e $file) {
         $self->die_msg("No such file $file");
      }
      $self->verbose_msg("Parsing file $file");
      $self->set_aug_file($file);
      for my $rule (@{$self->{rules}}) {
         $self->verbose_msg("Applying rule $rule to $file");
         $self->play_rule($rule, $file);
      }
   }
}

sub filter_files {
   my ($self, $files) = @_;

   my @filtered_files;

   if ($self->{syswide} == 1) {
      my $lens = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_LENS);
      $self->debug_msg("Finding files for lens $lens");
      my $sys_path = AUGEAS_META_TREE."/files//*[lens =~ regexp('@?${lens}(\.lns)?')]/path";
      $self->debug_msg($sys_path);
      for my $f ($self->{aug}->match($sys_path)) {
         my $p = $self->{aug}->get($f);
         $p =~ s|^/files||;
         $self->debug_msg("Found file $p");
         push @filtered_files, $p;
      }
   } else {
      my $pattern = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_PATTERN);
      my $exclude = $self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_EXCLUDE);
      $exclude ||= '^$';

      foreach my $file (@$files) {
         push @filtered_files, $file
            if ($file =~ /^$pattern$/ && $file !~ /^$exclude$/);
      }
   }

   return \@filtered_files;
}

sub tick {
   my ($self) = @_;

   $self->{tick}++;
   my $tick = $self->{tick} % 4;

   my $hourglass; 
    
   $hourglass = "|"  if ( $tick == 0 ); 
   $hourglass = "/"  if ( $tick == 1 ); 
   $hourglass = "-"  if ( $tick == 2 ); 
   $hourglass = "\\" if ( $tick == 3 ); 

   print colored ($hourglass, COLOR_INFO),"\b";
}

sub get_all_files {
   my ($self) = @_;

   my @files;

   $self->{aug}->load();
   for my $f ($self->{aug}->match(AUGEAS_META_TREE."/files//path[. != '']")) {
      my $p = $self->{aug}->get($f);
      $p =~ s|^/files||;
      push @files, $p;
   }

   return @files;
}

sub play {
   my ($self, @infiles) = @_;

   my @files;
   if ($self->{recurse}) {
      printf "\033[?25l"; # hide cursor
      print colored ("I: Recursively analyzing directories ", COLOR_INFO) unless $self->{quiet};
      find sub {
         my $exclude = $self->{exclude};
         $exclude ||= '^$';
         push @files, $File::Find::name
            if(-e && $File::Find::name !~ /^$exclude$/);
         $self->tick unless $self->{quiet}
         }, @infiles;
      print colored("[done]", COLOR_OK),"\n" unless $self->{quiet};
      printf "\033[?25h"; # restore cursor
   } elsif ($#infiles < 0) {
      @files = $self->get_all_files();
      $self->{syswide} = 1;
   }else {
      @files = @infiles;
   }
   
   if ($self->{conffile}) {
      $self->load_conf($self->{conffile});
      $self->play_one(@files);
   } else {
      my @rulesdirs = split(/:/, $self->{rulesdir});
      foreach my $rulesdir (@rulesdirs) {
	 opendir (RULESDIR, $rulesdir)
	    or die MSG_ERR.": Could not open rules directory $rulesdir: $!\n";
	 while (my $conffile = readdir(RULESDIR)) {
	    next unless ($conffile =~ /.*\.ini$/);
	    $self->{conffile} = "$rulesdir/$conffile";
	    $self->load_conf($self->{conffile});
	    next unless ($self->{cfg}->val(CONF_DEFAULT_SECTION, CONF_PATTERN));

	    my $filtered_files = $self->filter_files(\@files);
	    my $elems = @$filtered_files;
	    next unless ($elems > 0);

	    $self->play_one(@$filtered_files);
	 }
	 closedir(RULESDIR);
      }
   }
}


sub set_aug_file {
   my ($self, $file) = @_;

   my $absfile = `readlink -f $file`;
   chomp($absfile);

   my $aug = $self->{aug};
   my $lens = $self->{lens};


   if ($self->{syswide} != 1) {
      $aug->rm("/files");
      if ($aug->count_match(AUGEAS_META_TREE."/load/$lens/lens") == 0) {
         # Lenses with no autoload xfm => bet on lns
         $aug->set(AUGEAS_META_TREE."/load/$lens/lens", "$lens.lns");
      }

      $aug->rm(AUGEAS_META_TREE."/load/$lens/incl");
      $aug->set(AUGEAS_META_TREE."/load/$lens/incl", $absfile);
      $aug->load;
   }

   $aug->defvar('file', "/files$absfile");

   my $err_lens_path = AUGEAS_META_TREE."/load/$lens/error";
   my $err_lens = $aug->get($err_lens_path);
   if ($err_lens) {
      $self->err_msg("Failed to load lens $lens");
      $self->err_msg($aug->print($err_lens_path));
   }

   my $err_path = AUGEAS_META_TREE."/files$absfile/error";
   my $err = $aug->get($err_path);
   if ($err) {
      my $err_line_path = AUGEAS_META_TREE."/files$absfile/error/line";
      my $err_line = $aug->get($err_line_path);
      my $err_char_path = AUGEAS_META_TREE."/files$absfile/error/char";
      my $err_char = $aug->get($err_char_path);

      $self->err_msg("Failed to parse file $file");
      my $err_msg = ($err eq "parse_failed") ?
         "Parsing failed on line $err_line, character $err_char."
         : $aug->print($err_path);
      $self->die_msg($err_msg);
   }
}

sub confname {
   my ($self) = @_;

   assert_notempty('conffile', $self->{conffile});
   my $confname = $self->{conffile};
   $confname =~ s|.*/||;
   return $confname;
}


sub print_msg {
   my ($self, $msg, $level, $color) = @_;

   $level ||= MSG_INFO;
   $color ||= COLOR_INFO;

   my $confname = $self->confname();
   print STDERR colored ("$level:[$confname]: $msg", $color),"\n";
}

sub err_msg {
   my ($self, $msg) = @_;

   $self->print_msg($msg, MSG_ERR, COLOR_ERR);
}

sub die_msg {
   my ($self, $msg) = @_;

   $self->err_msg($msg);
   exit(1) unless $self->{nofail};
}

sub verbose_msg {
   my ($self, $msg) = @_;

   $self->print_msg($msg, MSG_VERBOSE, COLOR_VERBOSE) if $self->{verbose};
}

sub debug_msg {
   my ($self, $msg) = @_;

   $self->print_msg($msg, MSG_DEBUG, COLOR_DEBUG) if $self->{debug};
}

sub ok_msg {
   my ($self, $msg) = @_;

   $self->print_msg($msg, MSG_INFO, COLOR_OK) unless $self->{quiet};
}


sub play_rule {
   my ($self, $rule, $file) = @_;

   unless ($self->{cfg}->SectionExists($rule)) {
      $self->die_msg("Section '$rule' does not exist");
   }
   my $name = $self->{cfg}->val($rule, CONF_TYPE_NAME);
   assert_notempty(CONF_TYPE_NAME, $name);
   my $type = $self->{cfg}->val($rule, CONF_TYPE_TYPE);
   assert_notempty(CONF_TYPE_TYPE, $type);
   my $expr = $self->{cfg}->val($rule, CONF_TYPE_EXPR);
   assert_notempty(CONF_TYPE_EXPR, $expr);
   my $value = $self->{cfg}->val($rule, CONF_TYPE_VALUE);
   assert_notempty(CONF_TYPE_VALUE, $value);
   my $explanation = $self->{cfg}->val($rule, CONF_TYPE_EXPL);
   $explanation ||= '';
   my $level = $self->{cfg}->val($rule, CONF_TYPE_LEVEL);
   $level ||= CONF_LEVEL_ERR;

   return if ($level eq CONF_LEVEL_IGNORE);

   my @def_tags = @{$self->{tags}};
   my $rule_tags_str = $self->{cfg}->val($rule, CONF_TAGS);
   $rule_tags_str ||= '';
   if ($#def_tags >= 0) {
      $self->debug_msg("Defined tags for rule: $rule_tags_str");
      my @rule_tags = split(',', $rule_tags_str);
      my $tag_ok = 0;
      for my $tag (@def_tags) {
         if (grep(/^$tag$/, @rule_tags)) {
            $self->debug_msg("Matched tag $tag for rule $rule");
            $tag_ok = 1;
            last;
         }
      }
      unless ($tag_ok) {
         $self->verbose_msg("Ignoring rule $rule since no tags matched");
         return;
      }
   }

   $self->assert($name, $type, $expr, $value, $file, $explanation, $level);
}


sub print_error {
   my ($self, $level, $color, $file, $msg, $explanation) = @_;

   $self->print_msg($msg, $level, $color);
   print STDERR colored ("   $explanation.", $color),"\n";
}


sub line_num {
   my ($file, $position) = @_;
   open my $fh, '<', "$file" || die MSG_ERR.": Failed to open file: $!";

   my $cur_pos = 0;

   while (<$fh>) {
       if ($cur_pos < $position) {
          $cur_pos += length $_; 
       } else {
          last;
       }
   }

   return $.;
}


sub assert {
   my ($self, $name, $type, $expr, $value, $file, $explanation, $level) = @_;

   if ($type eq CONF_TYPE_COUNT) {
      my $count = $self->{aug}->count_match("$expr");
      if ($count != $value) {
         my $mlevel;
         my $mcolor;
         if ($level eq CONF_LEVEL_ERR) {
            $mlevel = MSG_ERR;
            $mcolor = COLOR_ERR;
	    $self->{err} = $self->{err_code};
         } elsif ($level eq CONF_LEVEL_WARN) {
            $mlevel = MSG_WARN;
            $mcolor = COLOR_WARN;
	    $self->{err} = $self->{warn_code};
         } else {
            $self->die_msg("Unknown level $level for assertion '$name'");
         }
         my $msg = "Assertion '$name' of type $type returned $count for file $file, expected $value.";

         # Print span if value = 0
         if ($value == 0) {
            my @lines;
            my $got_span = 0;
            for my $node ($self->{aug}->match("$expr")) {
               if ($self->{aug}->span($node)->{filename}) {
                  my $span_start = $self->{aug}->span($node)->{span_start};
                  push @lines, line_num($file, $span_start);
                  $got_span = 1;
               } else {
                  $self->debug_msg("No span information for node $node");
               }
            }
            $msg .= "\n   Found $count bad node(s) on line(s): ".join(', ', @lines)."."
               if $got_span;
         }
         $self->print_error($mlevel, $mcolor, $file, $msg, $explanation);
      }
   } else {
      $self->die_msg("Unknown type '$type'");
   }
}


sub assert_notempty {
   my ($name, $var) = @_;

   die MSG_ERR.": Variable '$name' should not be empty\n"
      unless (defined($var)); 
}


1;


__END__


=head1 NAME

   Config::Augeas::Validator - A generic configuration validator API

=head1 SYNOPSIS

   use Config::Augeas::Validator;

   # Initialize
   my $validator = Config::Augeas::Validator->new(rulesdir => $rulesdir);

   $validator->play(@files);
   exit $validator->{err};


$rulesdir points to one or more directories of rules, separated by colons.


=head1 CONFIGURATION

The B<Config::Augeas::Validator> configuration files are INI files.

=head2 DEFAULT SECTION

The B<DEFAULT> section is mandatory. It contains the following variables:

=over 8

=item B<lens>

The name of the lens to use, for example:

C<lens=Httpd>

=item B<err_code>

The exit code to return when a test fails. This parameter is optional. Example:

C<err_code=3>

=back

=head2 RULES

Each section apart from the B<DEFAULT> section defines a rule, as listed in the B<rules> variable of the B<DEFAULT> section. Each rule contains several parameters.

=over 8

=item B<name>

The rule description, for example:

C<name=Application Type>

=item B<explanation>

The explanation for the rule, for example:

C<explanation=Check that application type is FOO or BAR>

=item B<type>

The type of rule. For now, B<Config::Augeas::Validator> only supports the B<count> type, which returns the count nodes matching B<expr>. Example:

C<type=count>

=item B<expr>

The B<Augeas> expression for the rule. The C<$file> variable is the path to the file in the B<Augeas> tree. Example:

C<expr=$file/VirtualHost[#comment =~ regexp("^1# +((AI|BO)\+?|DR)$")]>

=item B<value>

The value expected for the test. For example, if using the count type, the number of matches expected for the expression. Example:

C<value=1>

=item B<level>

The importance level of the test. Possible values are 'error' (default) and 'warning'.
When set to 'error', a failed test will interrupt the processing and set the return code.
When set to 'warning', a failed test will display a warning, continue, and have no effect on the return code.
When set to 'ignore', the test is ignored and never run.

C<level=warning>

=back


=head1 SEE ALSO

L<Config::Augeas>

=head1 FILES

F</etc/augeas-validator/rules.d>
    The default rules directory for B<Config::Augeas::Validator>.

=cut

