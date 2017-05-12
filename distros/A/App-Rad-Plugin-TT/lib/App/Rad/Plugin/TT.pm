package App::Rad::Plugin::TT;

our $VERSION = "0.2";

use Template;

sub _default_obj {
   my $c = shift;

   Template->new(
                 INCLUDE_PATH       => $c->stash->{tt_include_path} || "."   ,
                 TEMPLATE_EXTENSION => $c->{tt_extension}    || ".tt2",
                );
}

sub tt_config {
   my $c      = shift;
   my $config = shift;

   $c->{'_tt_controler'} = delete $config->{CONTROLLER_VAR} if exists $config->{CONTROLLER_VAR};
   $c->{'_tt_config'} = $config;
   $c->{'_tt_obj'} = Template->new(%$config);
   $c->{'_tt_extension'} = $config->{TEMPLATE_EXTENSION} if exists $config->{TEMPLATE_EXTENSION};
}

sub _template_file {
   my $c = shift;

   if(exists $c->stash->{template}) {
      return $c->stash->{template};
   }else {
      return $c->cmd . ($c->{'_tt_extension'} || ".tt2");
   }
}

sub process {
   my $c = shift;

   $c->{'_tt_obj'} ||= _default_obj($c);
   my $tt_file = _template_file($c);
   my $output;
   $c->{'_tt_obj'}->process($tt_file, { ($c->{'_tt_controler'} || "c") => $c, %{$c->stash} }, \$output)
      || die $c->{'_tt_obj'}->error();
   $output;
}

sub process_array {
   my $c    = shift;
   my @vars = @{shift()};

   $c->stash->{template_obj} ||= _default_obj($c);
   my $tt_file = _template_file($c);
   my $output;
   for my $vars(@vars){
      my $output_part;
      $c->stash->{template_obj}->process($tt_file, {"c" => $c, %{$c->stash}, %$vars}, \$output_part)
         || die $c->stash->{template_obj}->error();
      $output .= $output_part;
   }
   $output;
}

sub use_tt_post_process {
   my $c = shift;

   my $old_post_process = $c->{"_old_post_process_TT"} = $c->{"_functions"}->{post_process};
   $c->{"_functions"}
      ->{post_process} = sub {
                                 my $c = shift;
                                 if($c->cmd) {
                                    $c->output($c->process);
                                 }
                                 $old_post_process->($c);
                             };
}

sub no_tt_post_process {
   my $c = shift;

   $c->{"_functions"}->{post_process} = $c->{"_old_post_process_TT"};
}

42;
