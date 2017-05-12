package Config::Yacp;
{
  use Object::InsideOut;
  use Parse::RecDescent;
  use Fcntl qw/:flock/;
  use Carp;
  use strict;
  use Data::Dumper;
  use vars qw($VERSION $grammar $CONFIG);

  $VERSION='2.00';
  BEGIN{ $::RD_AUTOACTION=q{ [@item[1..$#item]] }; }

  # Define the grammar
  $grammar = q(
                 file: section(s)
                 section: header pair(s?)
                 header:  /\[(\w+)\]/ { $1 }
                 pair:    /(\w+)\s?=\s?(\w+)?(\s+[;#][\s\w]+)?\n/
                 {
                   if(!defined $3){
                     [$1,$2];
                   }else{
                     [$1,$2,$3];
                   } 
                 }
              );
  my @FileName      :Field('Standard'=>'FileName','Type'=>'LIST');
  my @CommentMarker :Field('Standard'=>'CommentMarker','Type'=>'LIST');

  my %init_args :InitArgs=(
    'FileName'=>{
        'Regex' => qr/^FileName$/i,
	'Mandatory' => 1,
    },
    'CommentMarker'=>{
        'Regex' => qr/^CommentMarker$/i,
	'Default' => '#',
    }
  );

  sub _init :Init{
    my ($self,$args)=@_;
    if(exists($args->{'FileName'})){
      $self->set(\@FileName,$args->{'FileName'});
    }
    if(exists($args->{'CommentMarker'})){
      $self->set(\@CommentMarker,$args->{'CommentMarker'});
    }
    my $cm=$self->get_CommentMarker;
    if($cm!~/[#;]/){
      croak "Incorrect Comment Marker detected. Use either # or ; to mark comments";
    }
    my $parser = Parse::RecDescent->new($grammar);
    my $file=$self->get_FileName;
    my $ini;
    {
      no strict 'subs';
      $/=undef;
      open(FILE,"$file")||croak "Can't open $file: $!";
      flock(FILE,LOCK_SH) or die "Unable to obtain a file lock: $!\n";
      $ini=<FILE>;
      flock(FILE,LOCK_UN);
      close FILE;
    }

    my $tree = $parser->file($ini);
    $CONFIG = deparse($tree);
  }

  sub retrieve_sections{
    my @sections = sort keys %$CONFIG;
    return @sections;
  }

  sub retrieve_parameters{
    my ($self,$section)=@_;
    croak "No section given" if !defined $section;
    croak "Non-existent section given" if !exists $CONFIG->{$section};
    my @params = sort keys %{$CONFIG->{$section}};
    return @params;
  }

  sub retrieve_value{
    my($self,$section,$parameter)=@_;
    croak "Missing arguments" if scalar @_ < 3;
    croak "Non-existent section given" if !exists $CONFIG->{$section};
    croak "Non-existent parameter given" if !exists $CONFIG->{$section}->{$parameter};
    my $value=$CONFIG->{$section}->{$parameter}->[0];
    return $value;
  }

  sub change_value{
    my($self,$section,$parameter,$value)=@_;
    croak "Missing arguments" if scalar @_ < 4;
    croak "Non-existent section given" if !exists $CONFIG->{$section};
    croak "Non-existent parameter given" if !exists $CONFIG->{$section}->{$parameter};
    $CONFIG->{$section}->{$parameter}->[0]=$value;
  }

  sub retrieve_comment{
    my($self,$section,$parameter)=@_;
    croak"Missing arguments" if scalar @_ < 3;
    croak"Invalid section argument" if !exists $CONFIG->{$section};
    croak"Invalid parameter argument" if !exists $CONFIG->{$section}->{$parameter};
    if (!defined $CONFIG->{$section}->{$parameter}->[1]){
      local $SIG{__WARN__}=sub{ $@=shift; };
      carp"No comment available for this parameter";
    }else{
      my $comment=$CONFIG->{$section}->{$parameter}->[1];
      return $comment;
    }
  }

  sub add_section{
    my ($self,$section)=@_;
    croak"Missing arguments" if scalar @_ < 2;
    croak"Section exists!" if exists $CONFIG->{$section};
    $CONFIG->{$section}=undef;  
  }

  sub add_parameter{
    my ($self,$section,$para,$value,$comment)=@_;
    croak"Missing arguments" if scalar @_ < 4;
    if(!exists $CONFIG->{$section}){
      $self->add_section($section);
    }
    croak"Parameter exists" if exists $CONFIG->{$section}->{$para};
    $CONFIG->{$section}->{$para}=[$value];
    if(defined $comment){ push @{$CONFIG->{$section}->{$para}},$comment; } 
  }

  sub add_comment{
    my ($self,$section,$para,$comment)=@_;
    croak"Missing arguments" if scalar @_ < 4; 
    croak"Non-Existent section" if !exists $CONFIG->{$section};
    croak"Non-Existent parameter" if !exists $CONFIG->{$section}->{$para};
    $CONFIG->{$section}->{$para}->[1]=$comment;
  }

  sub display_config{
    print Dumper($CONFIG);
  }

  sub delete_section{
    my ($self,$section)=@_;
    croak"Missing arguments" if scalar @_ < 2;
    croak"Non-Existent section" if !exists $CONFIG->{$section};
    delete $CONFIG->{$section};
  }

  sub delete_parameter{
    my ($self,$section,$para)=@_;
    croak"Missing arguments" if scalar @_ < 3;
    croak"Non-Existent section" if !exists $CONFIG->{$section};
    croak"Non-Existent parameter" if !exists $CONFIG->{$section}->{$para};
    delete $CONFIG->{$section}->{$para};
  }

  sub delete_comment{
    my ($self,$section,$para)=@_;
    croak"Missing arguments" if scalar @_ < 3;
    croak"Non-Existent section" if !exists $CONFIG->{$section};
    croak"Non-Existent parameter" if !exists $CONFIG->{$section}->{$para};
    if(defined $CONFIG->{$section}->{$para}->[1]){
      pop @{$CONFIG->{$section}->{$para}};
    }else{
      local $SIG{__WARN__}=sub{ $@=shift; };
      carp"No comment located for that parameter";
    }
  }

  sub save{
    no strict "refs";
    my $self=shift;
    my $file=$self->get_FileName;
    my $CM=$self->get_CommentMarker;
    open FH,">$file"||die"Unable to open $file: $!\n";
    flock(FH,LOCK_EX) or die "Unable to obtain file lock: $!\n";
    foreach my $section(sort keys %{$CONFIG}){
      print FH "[$section]\n";
      foreach my $para(sort keys %{$CONFIG->{$section}}){
        print FH "$para = $CONFIG->{$section}{$para}[0]";
	if(defined $CONFIG->{$section}{$para}[1]){
	  print FH "    $CM$CONFIG->{$section}{$para}[1]\n";
	}else{
	  print FH "\n";
	}
      }
      print FH "\n";
    }
    flock(FH,LOCK_UN) or die"Unable to unlock file: $!\n";
    close FH;
  }

  sub deparse{
    my $tree=shift;
    my $deparsed={};
      for my $aref(@$tree){
        for my $sec(@$aref){
          my $hash=$deparsed->{$sec->[0]}={};
          for my $aref(@{$sec->[1]}){
	    $hash->{$aref->[0]}=[$aref->[1]];
	    if(my $cmmnt=$aref->[2]){
	      $cmmnt=~s/^\s+[#;]//;
              push @{$hash->{$aref->[0]}},$cmmnt;
            }
          }
        }
      }
    return $deparsed;
  }
1;
}
__END__

=head1 NAME

Config::Yacp - Yet Another Configuration Module 

=head1 SYNOPSIS

  use Config::Yacp;
  my $config = Config::Yacp->new(FileName=>'Config.ini');

  #retrieve the sections of the file
  my @sections = $config->retrieve_sections;

  #retrieve the parameters of a specific section
  my @parameters = $config->retrieve_parameters("Section1");

  #retrieve the value of a specific parameter
  my $value = $config->retrieve_value("Section1","Parameter1");

  #retrieve any comments attached to a parameter
  my $comment = $config->retrieve_comment("Section2","Parameter3");

  #add a new section
  $config->add_section("Section3");

  #add a parameter/value/comment to a section
  $config->add_parameter("Section3","Parameter5","Value5","Optional Comment");

  #change the value of a parameter
  $config->change_value("Section3","Parameter5","Value10");

  #delete a parameter
  $config->delete_parameter("Section3","Parameter5");

  #delete a section
  $config->delete_section("Section3");

  #delete a comment
  $config->delete_comment("Section2","Parameter3");

  #display the config file (uses Data::Dumper)
  $config->display_config;

  #save the .ini file with any changes
  $config->save;

=head1 DESCRIPTION

=over 5

=item new

C<< my $config = Config::Yacp->new(FileName=>'config.ini',CommentMarker=>';'); >>

This method creates the Config::Yacp object and loads the file into an internal hash within
the object.  The filename parameter is mandatory, and the CommentMarker parameter is an optional
one. Both parameter names are case insensitive. The default comment marker is
the # character. The only other character that can be used as a comment marker
is the ; character, which is used by Unreal Tournament config files.

=item retrieve_sections

C<< my @sections = $config->retrieve_sections; >>

This method retrieves the section names from the ini file.

=item retrieve_parameters

C<< my @params = $config->retrieve_parameters("Section1"); >>

This method retrieves the parameters for a given section. This method will croak if the section does not exist.

=item retrieve_value

C<< my $value = $config->retrieve_value('Section1','Parameter2'); >>

This method will retrieve the value of a given parameter within the specified section. It will croak if it
receives a non-existent section or parameter.

=item retrieve_comment

C<< my $comment = $config->retrieve_comment('Section2','Parameter2'); >>

This method will retrieve the comment attached to given parameter within a section. It will give a warning if
the parameter does not have a comment. It will croak if the given section or parameter is invalid.

=item change_value

C<< $config->change_value('Section2','Parameter4','NewValue'); >>

This method allows for the value of a specified parameter to be changed to a new value. It will croak if the
given section or parameter is invalid.

=item add_comment

C<< $config->add_comment('Section1','Parameter2',"New comment"); >>

This method will add a comment to a specified parameter within a section. It will croak if the given section
or parameter is invalid.

=item add_section

C<< $config->add_section('Section3'); >>

This method adds a new section to the configuration. It will give a warning if the section already exists.

=item add_parameter

C<< $config->add_parameter('Section3','Parameter5','Value5',"Optional comment"); >>

This method will add a new parameter and value to a specified section, along with an optiona comment. It will croak if
the section is invalid.

=item delete_section

C<< $config->delete_section('Section3'); >>

This method will delete the given section. If there are any parameter/values still associated with it, they will
be deleted as well. It will croak if the given section name is invalid.

=item delete_parameter

C<< $config->delete_parameter('Section3','Parameter5'); >>

This method will delete a specified parameter within a section. It will also remove any comments associated with that parameter.
It will croak if either the section or parameter name is invalid.

=item delete_comment

C<< $config->delete_comment('Section2','Parameter4'); >>

This method will delete a comment associated with the specified parameter within a section. It will give a warning if a comment is
not associated with the paramter.

=item display_config

C<< $config->display_config; >>

This method uses Data::Dumper to print to STDOUT the contents of the configuration variable within the Config::Yacp object.

=item save

C<< $config->save; >>

This method saves the contents of the configuration hash back to the file that it initially loaded the hash from.

=back

=head1 EXPORT

None by default.

=head1 TODO

The configuration is stored inside a hash. It should be changed to an AoA to provide less overhead and
an increase in performance.

=head1 SEE ALSO

L<Object::InsideOut>

L<Data::Dumper>

L<perl>

=head1 AUTHOR

Thomas Stanley, E<lt>Thomas_J_Stanley@msn.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2007 by Thomas Stanley 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
