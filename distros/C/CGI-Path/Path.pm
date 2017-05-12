#!/usr/bin/perl -w

package CGI::Path;

use strict;
use vars qw($VERSION);

$VERSION = "1.12";

use CGI;

sub new {
  my $type  = shift;
  my %DEFAULT_ARGS = (
    ### turn on keeping history, $self->form->{$self->{history_key}} also needs to be true
    allow_history         => 0,
    ### history_key is the key from the form to turn on history
    history_key           => 'history',

    ### turn on magic fill
    allow_magic_fill      => 0,
    ### turn on micro seconds, which requires Time::HiRes
    allow_magic_micro     => 0,
    ### full path to the magic_fill file
    magic_fill_filename   => '',

    ### if a given page doesn't exist, create it using create_page method
    create_page           => 0,

    ### form_name is used for javascript
    form_name             => 'MYFORM',
    form_keyname          => 'form',

    ### extension for htm files
    htm_extension         => 'htm',
    ### extension for validation files 
    val_extension         => 'val',

    ### if the user submits an empty form, keep the session
    keep_no_form_session  => 0,

    my_form               => {},
    my_path               => {},

    ### 'fake keys', stuff that gets skipped from the session
    not_a_real_key        => [qw(_begin_time _http_referer _printed_pages _session_id _submit _validated)],

    ### sort of a linked list of the path
    path_hash             => {
#      simple example
#      initial_step       => 'page1',
#      page1              => 'page2',
#      page2              => 'page3',
#      page3              => '',
    },

    ### used for requiring in files
    perl5lib              => $ENV{PERL5LIB} || '',

    ### only get these values from the session
    session_only          => ['_validated'],
    ### if these values are in the session and form, the session wins
    session_wins          => [],
    ### sometimes you might not want to use a session
    use_session           => 1,

    ### what got validated on this request
    validated_fresh       => {},

    ### a history of bless'ings
    WASA                  => [],
  );
  my $self = bless \%DEFAULT_ARGS, $type;

  $self->{my_module} ||= ref $self;
  $self->merge_in_args(@_);

  if($self->{use_session}) {
    $self->session;
  }

  ### don't always want to do all the extra stuff
  unless($self->{no_new_helper}) {
    $self->new_helper;
  }

  return $self;
}

sub session_dir {
  return '/tmp/path/session';
}

sub session_lock_dir {
  return '/tmp/path/session/lock';
}

sub cookies {
  my $self = shift;
  unless($self->{cookies}) {
    $self->{cookies} = {};
    my $query = CGI->new;
    foreach my $key ($query->cookie()) {
      $self->{cookies}{$key} = $query->cookie($key);
    }
  }
  return $self->{cookies};
}

sub DESTROY {
  my $self = shift;
}

sub new_session {
  my $self = shift;
  my ($sid, $session_dir, $session_lock_dir) = @_;
  require Apache::Session::File;
  $self->{session} = {};
  tie %{$self->{session}}, 'Apache::Session::File', $sid, {
    Directory     => $session_dir,
    LockDirectory => $session_lock_dir,
  };
  $self->set_sid($self->{session}{_session_id});
}

sub session {
  my $self = shift;
  my $opt = shift;
  unless($self->{session}) {
    eval {
      $self->new_session($self->sid, $self->session_dir, $self->session_lock_dir);
    };
    if($@) {
      if($@ =~ /Object does not exist/i) {
        eval {
          $self->new_session('', $self->session_dir, $self->session_lock_dir);
        };
      }
    }
    die $@ if($@);
  }
  if($opt) {
    my $opt_ref = ref $opt;
    if($opt_ref) {
      if($opt_ref eq 'HASH') {
        foreach(keys %{$opt}) {
          $self->{session}{$_} = $opt->{$_};
        }
      }
    } else {
      die "I got not a ref on session opt";
    }
  }
  return $self->{session};
}

sub sid_cookie_name {
  my $self = shift;
  return $self->my_content . "_sid";
}

sub set_cookie {
  my $self = shift;
  my ($cookie_name, $cookie_value) = @_;
  my $new_cookie = CGI::cookie
    (-name  => $cookie_name,
     -value => $cookie_value,
     );
  if (exists $ENV{CONTENT_TYPED}) {
    print qq{<meta http-equiv="Set-Cookie" content="$new_cookie">\n};
  } else {
    print "Set-Cookie: $new_cookie\n";
  }
  return;
}

sub set_sid {
  my $self = shift;
  my $sid = shift;
  $self->set_cookie($self->sid_cookie_name, $sid);
}

sub sid {
  my $self = shift;
  return $self->cookies->{$self->sid_cookie_name} || '';
}

sub merge_in_args {
  my $self = shift;
  my %PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  foreach my $passed_arg (keys %PASSED_ARGS) {
    if(ref $PASSED_ARGS{$passed_arg} && ref $PASSED_ARGS{$passed_arg} eq 'HASH') {
      foreach my $key (keys %{$PASSED_ARGS{$passed_arg}}) {
        $self->{$passed_arg}{$key} = $PASSED_ARGS{$passed_arg}{$key};
      }
    } else {
      $self->{$passed_arg} = $PASSED_ARGS{$passed_arg}
    }
  }
}

### morph methods

sub morph_path {
  my $self = shift;
  my $my_module = shift || $self->my_module;

  # morph to my_module
  if($my_module) {
    $self->morph($my_module, 1);
  }

}

sub morph_step {
  my $self = shift;

  my $step = shift;
  # going to morph based on my_module

  my $full_step = $self->my_module . "::$step";

  # morph to something like CGI::Path::Skel::page_one
  # the 1 turns on the -e check
  $self->morph($full_step, 1);
  
}

sub morph {
  my $self = shift;

  my $starting_ref = ref $self;

  my $package = shift;
  my $do_dash_e_check = shift;

  my $tmp_package = $package;
  $tmp_package =~ s@::@/@g;

  my $path = "$tmp_package.pm";

  my $exists = 1;

  # if they don't want to force the require, I will check -e before morphing
  if($do_dash_e_check) {
    my $full_path = "$self->{perl5lib}/$path";
    $exists = -e $full_path;
  }

  if($exists) {
    ### polymorph
    eval {
      require $path;
    };
    if( $@ ){
      $self->{errstr} = "bad stuff on require of $tmp_package.pm: $@";
      die $@;
    }
    bless $self, $package;
  }

  my $ending_ref = ref $self;

  my $sub_ref = $self->can('add_WASA');
  if($sub_ref) {
    &$sub_ref($self, $starting_ref);
    &$sub_ref($self, $ending_ref);
  }
  return $self;
}

sub add_WASA {
  my $self = shift;
  my $ref = shift;
  push @{$self->{WASA}}, $ref unless(grep { $_ eq $ref } @{$self->{WASA}});
}


sub my_module {
  my $self = shift;
  return $self->{my_module};
}

sub base_include_path {
  my $self = shift;
  die "please write your own base_include_path method";
}

sub include_path {
  my $self = shift;
  return [$self->base_include_path . "/default"];
}

sub my_content {
  my $self = shift;
  return $self->{my_content} ||= do {
    my $my_content = lc($self->my_module);
    my $this_package = __PACKAGE__;
    $my_content =~ s/^${this_package}:://i;
    $my_content =~ s@::@/@g;
    $my_content; # return of the do
  };
}




sub new_helper {
  my $self = shift;

  if(!$self->{keep_no_form_session} && !scalar keys %{$self->this_form} && 
    scalar keys %{$self->session}) {
    #warn "User posted an empty form with a non empty session.\n";
    $self->session_wipe;
  }

  $self->generate_form;
  $self->morph_path;
  $self->get_path_array;

  unless($self->session->{_begin_time}) {
    $self->session({
      _begin_time => time,
    });
  }
  if($ENV{HTTP_REFERER} && $ENV{SCRIPT_NAME}
  && $ENV{HTTP_REFERER} !~ $ENV{SCRIPT_NAME}) {
    $self->session({
      _http_referer => $ENV{HTTP_REFERER},
    });
  }
}

sub delete_session {
  my $self = shift;
  delete $self->{session};
}

sub session_wipe {
  my $self = shift;
  $self->delete_cookie($self->sid_cookie_name);
  $self->delete_session;
  if(keys %{$self->this_form}) {
    die "need to get session_wipe to work generally";
  }
}

sub delete_cookie {
  my $self = shift;
  my $cookie_name = shift || die "need a cookie_name for delete_cookie";

  if($self->cookies->{$cookie_name}) {
    delete $self->cookies->{$cookie_name};
    $self->set_cookie($cookie_name, '');
  }
}

sub get_path_array {
  my $self = shift;

  my $path_hash = $self->path_hash;

  $self->{path_array} = [];
  my $next_step = $self->initial_step || die "need an initial_step";
  while($next_step) {
    die "infinite loop on $next_step" if(grep {$next_step eq $_ } @{$self->{path_array}});
    push @{$self->{path_array}}, $next_step;

    $next_step = $path_hash->{$next_step};
  }
  return $self->{path_array};
}

sub session_form {
  return {};
}

sub generate_form {
  # generate_form takes two hashes
  # $self->this_form - the results of CGI get form
  # $self->session   - the stuff from the session file
  # and merges them into
  # $self->{form} - the place to use
  my $self = shift;
  my $form = {};

  my $this_form = $self->this_form;
  # some things we want to just get from the session
  foreach(@{$self->{session_only}}) {
    delete $this_form->{$_};
    $form->{$_} = $self->session->{$_} if(exists $self->session->{$_});
  }

  # there might be some stuff we want to give session precedence to
  foreach(@{$self->{session_wins}}) {
    $form->{$_} = $self->session->{$_} if(exists $self->session->{$_});
  }

  # lay the hashes on top of each other in reverse order of precedence
  $self->form({%{$self->session}, %{$this_form}, %{$form}});
  if($self->form->{session_wipe}) {
    $self->session_wipe;
    $self->clear_value('session_wipe');
  }
}

sub this_form {
  my $self = shift;
  return $self->{this_form} ||= do {
    my $cgi = CGI->new;
    my %form = $cgi->Vars;
    foreach(keys %form) {
      next unless($form{$_} =~ /\0/);
      $form{$_} = [split /\0/, $form{$_}];
    }
    \%form;
  }
}

sub empty_form {
  my $self = shift;
  my $form = $self->form;
  my $empty_form = 1;
  foreach my $key (keys %{$form}) {
    next if(grep { $_ eq $key } @{$self->{not_a_real_key}});
    $empty_form = 0;
    last;
  }
  return $empty_form;
}

sub form {
  my $self = shift;
  $self->{$self->{form_keyname}} = shift if($#_ != -1);
  return $self->{$self->{form_keyname}} ||= {};
}

### history methods

sub allow_history {
  my $self = shift;
  my $return = 0;
  if($self->{allow_history} && $self->form->{$self->{history_key}}) {
    unless($self->session->{$self->{history_key}}) {
      $self->session({
        $self->{history_key} => $self->form->{$self->{history_key}},
      });
    }
    $return = 1;
  }
  return $return;
}

sub history_window_name {
  my $self = shift;
  return $self->my_content . "_window";
}

sub show_history {
  my $self = shift;
  return unless($self->allow_history);
  $self->my_content_type;
  my $window_name = $self->history_window_name;
  $window_name =~ s/\W//g;
  my $out = $self->out('history.tt', {
    history => $self->{history}
  });
  $$out =~ s@\n@\\n@g;
  $$out =~ s@(</?sc)(ript>)@$1" + "$2@ig;
  print <<SCRIPT;
<SCRIPT>
var w=window.open('', '$window_name', '');
if(w) {
  w.document.open();
  w.document.write("$$out");
  w.document.close();
}
</SCRIPT>
SCRIPT
}

sub history_init {
  my $self = shift;
  if($self->allow_history) {
    $self->{history} = [];
  }
}

sub hook_history_init {
  my $self = shift;
  if($self->allow_history) {
    $self->{_history} ||= {};
    $self->{_history}{hook} = [];
  }
}

sub add_history_step {
  my $self = shift;
  if($self->allow_history) {
    my $step = shift || die "need a step";
    $self->{_history}{hash} = {};
    $self->{_history}{hash}{step} = $step;
  }
}

sub history_push {
  my $self = shift;
  if($self->allow_history) {
    push @{$self->{history}}, $self->{_history}{hash};
    delete $self->{_history};
  }
}

sub hook_history_add {
  my $self = shift;
  if($self->allow_history) {
    my $hash = shift || die "need a hook history hash";
    push @{$self->{_history}{hash}{hook}}, $hash;
  }
}

### where lots of the magic happens

sub navigate {
  my $self = shift;

  my $form = $self->form;
  my $path = $self->get_path_array;

  $self->history_init;

  $self->handle_jump_around;

  my $previous_step = $form->{_printed_pages} && $form->{_printed_pages}[-1] ? $form->{_printed_pages}[-1] : '';

  ### sub_ref is where I put references to subroutines that can returned
  my $sub_ref;

  &$sub_ref($self) if($sub_ref = $self->can('pre_navigate_walk'));
  
  ### foreach path, run the gamut of routines
  my $return_val = undef;
  foreach my $step (@$path){
    
    $self->add_history_step($step);

    return 1 if($self->{stop_navigate});
    $self->morph_step($step);

    $self->{this_step} = {
      this_step     => $step,
      previous_step => $previous_step,
      validate_ref  => $self->get_validate_ref($step),
    };
    
    my $method_pre  = "${step}_hook_pre";
    my $method_fill = "${step}_hash_fill";
    my $method_form = "${step}_hash_form";
    my $method_err  = "${step}_hash_errors";
    my $method_step = "${step}_step";
    my $method_post = "${step}_hook_post";

  # my $method_val  = "${step}_validate";
  #     method_val gets called in $self->validate

    ### a hook beforehand
    if($sub_ref = $self->can($method_pre)){
      $return_val = &$sub_ref($self);
      $self->hook_history_add({
        hook   => $method_pre,
        could  => 'Y',
        return => $return_val,
      });
      unless($return_val) {
        $self->hook_history_add({
          hook   => $method_pre,
          could  => 'Y',
          return => $return_val,
        });
        $self->history_push;

        next;
      }
    } else {
      $self->hook_history_add({
        hook   => $method_pre,
        could  => 'N',
        return => undef,
      });
    }

    my $validated = 1;
    my $info_exists;

    if($self->info_exists($step)) {
      $info_exists = 1;

      $self->hook_history_add({
        hook   => 'info_exists',
        could  => 'Y',
        return => join(", ", @{$self->{_extant_info}}),
      });

      $validated = $self->validate($step);

      $self->hook_history_add({
        hook   => 'validate',
        could  => 'Y',
        return => $validated,
      });

    } else {
      $info_exists = 0;

      $self->hook_history_add({
        hook   => 'info_exists',
        could  => 'Y',
        return => $info_exists,
      });

    }

    ### see if information is complete for this step
    if( ! $info_exists || ! $validated) {

      if($sub_ref = $self->can($method_fill)) {
        my $fill_return = $self->add_to_fill(&$sub_ref($self));

        $self->hook_history_add({
          hook   => $method_fill,
          could  => 'Y',
          return => $fill_return,
        });

      } else {

        $self->hook_history_add({
          hook   => $method_fill,
          could  => 'N',
          return => undef,
        });

      }

      $self->add_to_fill($self->form, 'smart_merge');
      $self->hook_history_add({
        hook   => 'add_to_fill',
        could  => 'Y',
        return => $self->form,
      });

      if(!$info_exists || $self->{magic_fill_regardless}) {

        if($self->allow_magic_fill) {
          my $magic_fill_ref = $self->magic_fill_ref;
          if(scalar keys %{$magic_fill_ref}) {
            $self->add_to_fill($magic_fill_ref, 'smart_merge');
          }

          $self->hook_history_add({
            hook   => 'magic_fill',
            could  => 'Y',
            return => undef,
          });

        }

      }

      my $hash_form;
      if($sub_ref = $self->can($method_form)) {
        $hash_form = &$sub_ref($self);

        $self->hook_history_add({
          hook   => $method_form,
          could  => 'Y',
          return => $hash_form,
        });

      } else {
        $hash_form = {};

        $self->hook_history_add({
          hook   => $method_form,
          could  => 'N',
          return => undef,
        });

      }

      my $hash_err;
      if($sub_ref = $self->can($method_err)) {
        $hash_err = &$sub_ref($self);

        $self->hook_history_add({
          hook   => $method_err,
          could  => 'Y',
          return => $hash_err,
        });

      } else {
        $hash_err = {};

        $self->hook_history_add({
          hook   => $method_err,
          could  => 'N',
          return => undef,
        });

      }

      my $page_to_print;
      if($sub_ref = $self->can($method_step)) {
        my $potential_page_to_print = &$sub_ref($self);

        # want to make this the page_to_print only if it a real page
        if($potential_page_to_print && !ref $potential_page_to_print && $potential_page_to_print !~ /^\d+$/) {
          $page_to_print = $potential_page_to_print 
        }

        $self->hook_history_add({
          hook   => $method_step,
          could  => 'Y',
          return => "$page_to_print ($potential_page_to_print)",
        });


      } else {

        $self->hook_history_add({
          hook   => $method_step,
          could  => 'N',
          return => undef,
        });

      }

      $page_to_print ||= $self->my_content . "/$step";

      my $val_ref = $self->{this_step}{validate_ref};
      $self->{my_form}{js_validation} ||= $self->generate_js_validation($val_ref);

      $self->hook_history_add({
        hook   => 'print',
        could  => 'Y',
        return => "printing $page_to_print",
      });
      $self->history_push;

      $self->print($page_to_print,
                   $hash_form,
                   $hash_err,
                   );
      return;
    }

    $self->history_push;

    ### a hook after
    if($sub_ref = $self->can($method_post)) {
      $return_val = &$sub_ref($self);
      if($return_val) {
        next;
      }
    }

  }
  return if $return_val;

  return $self->print($self->my_content . "/" . $self->initial_step ,$form);
}

sub generate_js_validation {
  my $self = shift;

  my $val_ref = shift || die "need a val_ref";
  my $form_name = $self->{form_name} || die "need a form name";

  require CGI::Ex::Validate;
  my $val = CGI::Ex::Validate->new($self->validate_new_hash($val_ref));
  
  ### yes, sort of dumb, but gets rid of variable only used once warning
  $CGI::Ex::Validate::JS_URI_PATH_VALIDATE = $CGI::Ex::Validate::JS_URI_PATH_VALIDATE = "/validate.js";
  $CGI::Ex::Validate::JS_URI_PATH_YAML     = $CGI::Ex::Validate::JS_URI_PATH_YAML     = "/yaml_load.js";

  return $val->generate_js($val_ref, $form_name);
}

### handle_jump_around aims to help keep things nice when a user goes back and resubmits a page
sub handle_jump_around {
  my $self = shift;

  my $path = $self->get_path_array;

  foreach my $step (reverse @{$path}) {
    if($self->fresh_form_info_exists($step)) {
      my $save_validated = delete $self->form->{_validated}{$step};

      foreach my $page_to_check ($step, @{$self->pages_after_page($step)}) {

        if($self->page_has_displayed($page_to_check)) {
          my $cleared = 0;
          my $val_hash = $self->get_validate_ref($page_to_check);

          foreach my $val_key (keys %{$val_hash}) {
            next unless($val_hash->{$val_key} && ref $val_hash->{$val_key} && ref $val_hash->{$val_key} eq 'HASH');
            if($val_hash->{$val_key}{WipeOnBack} && (! exists $self->this_form->{$val_key}) && exists $self->form->{$val_key}) {
              $self->clear_value($val_key);
              $cleared = 1;
            }
          }

          if($cleared) {
            $save_validated .= delete $self->form->{_validated}{$page_to_check};
            ### need to make it look like these pages never got printed
            for(my $i=(scalar @{$self->form->{_printed_pages}}) - 1;$i>=0;$i--) {
              if($self->form->{_printed_pages}[$i] eq $page_to_check) {
                splice @{$self->form->{_printed_pages}}, $i, 1;
              }
            }
            $self->session({
              _printed_pages => $self->form->{_printed_pages},
            });
          }
        }
      }
      if($save_validated) {
        $self->save_value('_validated');
      }
    }
  }
}

sub pages_after_page {
  my $self = shift;
  my $step = shift;
  my $return = [];
  my $after = 0;
  foreach my $path_step (@{$self->get_path_array}) {
    push @{$return}, $path_step if($after);
    if($path_step eq $step) {
      $after = 1;
    }
  }
  return $return;
}

sub get_real_keys {
  my $self = shift;
  my $real_keys = {%{$self->form}} || {};
  foreach(@{$self->{not_a_real_key}}) {
    delete $real_keys->{$_};
  }
  return $real_keys;
}

sub handle_unvalidated_keys {
  my $self = shift;
  my $path = $self->get_path_array;

  my $form = $self->form;

  my $validated = $form->{_validated} || {};
  my $mini_validated = {%$validated};
  my $unvalidated_keys = $self->get_real_keys;

  foreach my $step (@$path){
    last unless(keys %{$unvalidated_keys});
    my $val_hash = $self->get_validate_ref($step);
    if($mini_validated->{$step}) {
      foreach (keys %{$val_hash}) {
        delete $unvalidated_keys->{$_};
      }
      next;
    }

    my $to_save = {};
    foreach(keys %{$unvalidated_keys}) {
      if($val_hash->{$_} && $unvalidated_keys->{$_} && $form->{$_} && !$val_hash->{$_ . "_error"}) {
        $to_save->{$_} = $form->{$_};
        delete $unvalidated_keys->{$_};
      }
    }
    if(keys %$to_save) {
      $self->session($to_save);
    }
  }
}

sub initial_step {
  my $self = shift;
  return $self->path_hash->{initial_step};
}

sub path_hash {
  my $self = shift;
  return $self->{path_hash} || die "need a hash ref for \$self->{path_hash}";
}

sub my_path {
  my $self = shift;
  $self->{my_path}{$self->my_content} ||= {};
  return $self->{my_path}{$self->my_content};
}

sub my_path_step {
  my $self = shift;
  my $step = shift;
  $self->my_path->{$step} ||= {};
  return $self->my_path->{$step};
}

sub get_validate_ref {
  my $self = shift;

  my $step = shift;
  my $return;
  my $step_hash = $self->my_path_step($step);
  if($step_hash && $step_hash->{validate_ref}) {
    $return = $step_hash->{validate_ref};
  } elsif($self->{validate_refs}) {

    ### can break out validate refs by content chunk
    if($self->{validate_refs}{$self->my_content} && $self->{validate_refs}{$self->my_content}{$step}) {
      $return = $self->{validate_refs}{$self->my_content}{$step};

    ### or just by step
    } elsif($self->{validate_refs}{$step}) {
      $return = $self->{validate_refs}{$step};
    }
  }
  unless($return) {
     $return = $self->include_validate_ref($self->my_content . "/$step");
  }
  $step_hash->{validate_ref} = $return;
  return $return;
}

sub include_validate_ref {
  my $self = shift;

  # step is the full step like path/skel/enter_info
  my $step = shift;

  my $val_filename = $self->get_full_path($self->step_with_extension($step, 'val'));
  return -e $val_filename ? $self->conf_read($val_filename) : {};
}

sub conf_read {
  my $self = shift;
  my $filename = shift;
  require YAML;
  my $ref;
  eval {
    $ref = YAML::LoadFile($filename);
  };
  if($@) {
    die "YAML error: $@";
  }
  return $ref;
}

sub page_name_helper {
  my $self = shift;
  my $base_page = shift || die "need a \$base_page for page_name_helper";
  $base_page = "content/$base_page" unless($base_page =~ m@^(conf|content|images|template)/@);
  $base_page .= ".$self->{htm_extension}" unless($base_page =~ /\.\w+$/);
  return $base_page;
}

sub get_full_path {
  my $self = shift;
  my $relative_path = shift;
  $relative_path = $self->page_name_helper($relative_path);
  my $dirs = shift || $self->include_path;
  my $full_path = '';
  foreach my $dir (GET_VALUES($dirs)) {
    my $this_path = "$dir/$relative_path";
    if(-e $this_path) {
      $full_path = $this_path;
      last;
    }
  }
  return $full_path;
}

sub fresh_form_info_exists {
  my $self = shift;
  my $step = shift;
  my $return = 0;
  if($self->non_empty_val_ref($step) && $self->info_exists($step, $self->this_form)) {
    $return = 1;
  }
  return $return;
}

sub non_empty_val_ref {
  my $self = shift;
  my $step = shift;
  
  my $val_hash = $self->get_validate_ref($step);
  return $self->non_empty_ref($val_hash);
}

sub non_empty_ref {
  my $self = shift;
  my $ref = shift;
  my $non_empty = 0;
  if($ref) {
    my $ref_ref = ref $ref;
    if($ref_ref) {
      if($ref_ref eq 'HASH') {
        $non_empty = (scalar keys %{$ref}) ? 1 : 0;
      } elsif($ref_ref eq 'ARRAY') {
        $non_empty = (@{$ref}) ? 1 : 0;
      }
    }
  }
  return $non_empty;
}

sub info_exists {
  my $self = shift;
  my $step = shift;
  my $form = shift || $self->form;
  
  my $val_ref = $self->get_validate_ref($step);

  my $return = 0;
  ### default to info exists on an empty val_ref
  unless($self->non_empty_ref($val_ref)) {
    $return = 1;
  }
  
  $self->{_extant_info} = [];
  my $validating_keys = $self->get_validating_keys($val_ref);
  #if there exists one key in the form that matches
  #one key in the validate_ref return true
  foreach(@{$validating_keys}) {
    if(exists $form->{$_}) {
      $return = 1;
      push @{$self->{_extant_info}}, $_;
    } 
  }
  return $return;
}

sub get_validating_keys {
  my $self = shift;
  my $val_ref = shift;
  require CGI::Ex::Validate;
  my $val = CGI::Ex::Validate->new;
  my $keys = $val->get_validation_keys($val_ref);
  return [sort keys %{$keys}];
}

sub page_has_displayed {
  my $self = shift;
  my $page = shift;
  return (grep $_ eq $page, @{$self->form->{_printed_pages}});
}

sub page_was_just_printed {
  my $self = shift;
  my $page = shift;
  return (
    # were we passed a page
    $page
     &&
    # we have printed_pages
    ($self->form->{_printed_pages})
     &&
    # we have an array
    (ref $self->form->{_printed_pages} eq 'ARRAY')
     &&
    # we have a non empty array
    ( scalar @{$self->form->{_printed_pages}})
     &&
    # was $page the last entry
    $self->form->{_printed_pages}[-1] eq $page
  );
}

sub validate {
  my $self = shift;
  my $validated = $self->form->{_validated} || {};

  my $this_step = $self->{this_step}{this_step};
  my $return = 1;

  my $show_errors = 1;
  if(!$self->page_was_just_printed($this_step) || !$self->fresh_form_info_exists($this_step)) {
    $show_errors = 0;
  }

  my $sub_ref;
  my $method_pre_val = "$self->{this_step}{this_step}_pre_validate";
  if($sub_ref = $self->can($method_pre_val)) {
    my $pre_val_return = &$sub_ref($self, $show_errors);
    $self->hook_history_add({
      hook   => 'pre_val',
      could  => 'Y',
      return => $pre_val_return,
    });
    $return = $pre_val_return && $return;
  } else {
    $self->hook_history_add({
      hook   => 'pre_val',
      could  => 'N',
      return => '',
    });
  }

  if($validated->{$this_step}) {


  } else {

    ### validate_proper returns the number of errors it found
    ### so, 0 means success
    my $validate_proper_return = $self->validate_proper($self->form, $self->{this_step}{validate_ref}, $show_errors);
    $self->hook_history_add({
      hook   => 'validate_proper',
      could  => 'Y',
      return => $validate_proper_return,
    });

    if($validate_proper_return) {

      $return = 0;

    } else {
      $self->{validated_fresh}{$this_step} = 1;
      $validated->{$this_step} = 1;
      my $validated_hash = {
        _validated => $validated,
      };

      $self->form->{_validated} = $validated;
      # going to save the keys that have been validated to the session
      foreach my $key (@{$self->get_validating_keys($self->{this_step}{validate_ref})}) {
        $validated_hash->{$key} = $self->form->{$key};
      }
      $self->session($validated_hash);
    }
  }
  if($return) {
    my $method_post_val = "$self->{this_step}{this_step}_post_validate";
    if($sub_ref = $self->can($method_post_val)) {
      my $post_val_return = &$sub_ref($self, $show_errors);
      $self->hook_history_add({
        hook   => 'post_val',
        could  => 'Y',
        return => $post_val_return,
      });
      $return = $post_val_return && $return;
    }
  }

  if(!$return) {
    my $change = '';
    foreach my $check_page ($this_step, @{$self->pages_after_page($this_step)}) {
      $change .= (delete $validated->{$check_page}||'');
    }
    if($change) {
      $self->session({
        _validated => $validated,
      });
    }
  }
  return $return;
}

sub validate_new_hash {
  return {};
}

sub validate_proper {
  my $self = shift;
  my $form = shift;
  my $val_ref = shift;
  my $show_errors = shift;

  require CGI::Ex::Validate;
  my $errobj = CGI::Ex::Validate->new($self->validate_new_hash($val_ref))->validate($form, $val_ref);
  my $return = 0;
  if($errobj) {
    my $error_hash = $errobj->as_hash;
    if($show_errors) {
      $return = $self->add_my_error($error_hash);
    } else {
      $return = scalar keys %{$error_hash};
    }
  }
  return $return;
}

sub save_value {
  my $self = shift;
  my $name = shift;

  if (!ref $name) {
    $self->session({
      $name => $self->form->{$name}
    });
  } else {
    foreach my $key (keys %{$name}) {
      $self->form->{$key} = $name->{$key};
    }
    $self->session($name);
  }
}

sub clear_value {
  my $self = shift;
  my $name = shift;

  delete $self->form->{$name};
  delete $self->fill->{$name};
  delete $self->session->{$name};
}

sub add_my_error {
  my $self = shift;
  my $errors = shift;

  unless(ref $errors && ref $errors eq 'HASH') {
    die "need to send a hash ref of errors" 
  }

  my $added = 0;
  $self->{my_form}{errors} ||= {};

  foreach my $key (keys %{$errors}) {
    next unless($errors->{$key});
    $added++;
    $self->{my_form}{errors}{$key} = $errors->{$key};
  }

  ### returns how many errors were added
  return $added;
}

sub fill {
  my $self = shift;
  $self->{fill} ||= {};
  return $self->{fill};
}

sub add_to_fill {
  my $self = shift;

  my $fill_to_add = shift;
  my $smart_merge = shift;
  
  foreach(keys %{$fill_to_add}) {
    next if($smart_merge && exists $self->fill->{$_});
    $self->fill->{$_} = $fill_to_add->{$_};
  }
}

sub preload {
  my $self = shift;
  foreach my $step (@{$self->{path_array}}) {
    my $page = $self->page_name_helper($self->my_content . "/$step");
    my $ref = $self->get_validate_ref($step);
    $self->process($page, {});
  }
}

sub out {
  my $self = shift;
  my $page = shift || die "need a page to \$self->out";
  my $form = shift || {};

  $page = $self->page_name_helper($page);
  my $out = $self->process($page, $form);
  $out = \$out unless(ref $out);
  $self->fill_in($out);
  return $out;
}

sub print {
  my $self = shift;
  my $step = shift;

  $self->handle_unvalidated_keys;

  my $out;

  if($self->{htm} && $self->{htm}{$step}) {
    my $content = $self->{htm}{$step};
    $self->template->process(\$content, $self->uber_form, \$out) || die $self->template->error;
    $self->fill_in(\$out);

  } elsif (!-e $self->get_full_path($self->step_with_extension($step, 'htm'))) {
    $out = $self->create_page($step);
    die "couldn't find content for page: $step" unless($out);
    $self->fill_in(\$out);
  }

  $self->record_page_print;
  $self->my_content_type($step);
  print $out ? $out : ${$self->out($step, $self->uber_form(\@_))};
}

sub fill_in {
  my $self = shift;
  my $content = shift;
  die "need a scalar ref for \$content" unless($content && ref $content && ref $content eq 'SCALAR');
  my $hashref = shift || $self->fill;
  if($self->{uber_form}{fill}) {
    foreach(keys %{$self->{uber_form}{fill}}) {
      $hashref->{$_} = $self->{uber_form}{fill}{$_};
    }
  }
  require CGI::Ex;
  my $cgix = CGI::Ex->new;
  $cgix->fill({text => $content, form => $hashref});
}

### magic fill methods

sub allow_magic_fill {
  my $self = shift;
  return $self->{allow_magic_fill} ? 1 : 0;
}

sub magic_fill_interpolation_hash {
  my $self = shift;

  my ($script) = $0 =~ m@(?:.+/)?(.+)@;
  my ($_script) = $script =~ m@.*_(.+)@;
  $_script ||= $script;

  my $hash = {
    localtime => scalar (localtime),
    script     => $script,
    _script    => $_script,
    time       => time,
    %ENV,
  };
  if($self->{allow_magic_micro}) {
    require Time::HiRes;
    $hash->{micro} = join(".", &Time::HiRes::gettimeofday());
    $hash->{micro_part} = (&Time::HiRes::gettimeofday())[1];
  };
  return $hash;
}

sub magic_fill_ref {
  my $self = shift;

  my $filename = shift || $self->{magic_fill_filename};

  my $ref = {};

  if(open(FILE, $filename)) {

    my $file = join("", <FILE>);

    my $out = '';
    $self->process(\$file, $self->magic_fill_interpolation_hash, \$out);

    while($out =~ /^(.+)$/mg) {
      my $line = $1;
      next if($line =~ /^\s*#/);
      my ($keys, $value) = split /\s+/, $line, 2;
      foreach my $key (split /,/, $keys) {
        my $this_value = $value;
        $this_value =~ s/\$key_name/$key/g;
        $ref->{$key} = $this_value;
      }
    }

  }

  return $ref;
}

sub uber_form {
  my $self = shift;
  my $others = shift || [];

  foreach my $hash (@{$others}) {
    next unless($hash && ref $hash && ref $hash eq 'HASH');
    foreach (keys %{$hash}) {
      next if(/^_/);
      $self->{uber_form}{$_} = $hash->{$_};
    }
  }

  $self->{uber_form} ||= {};
  $self->{uber_form}{fill} ||= {};
  foreach (keys %{$self->form}) {
    next if(/^_/);
    $self->{uber_form}{$_} = $self->form->{$_};
  }
  foreach (keys %{$self->{my_form}}) {
    $self->{uber_form}{$_} = $self->{my_form}->{$_};
  }
  foreach (keys %{$self->fill}) {
    next if(/^_/);
    $self->{uber_form}{fill}{$_} = $self->fill->{$_};
  }
  $self->{uber_form}{script_name} = $ENV{SCRIPT_NAME} || '';
  $self->{uber_form}{path_info} = $ENV{PATH_INFO} || '';
  return $self->{uber_form};
}

sub process {
  my $self = shift;
  my $step_filename = shift || die "need a \$step_filename to \$self->process";
  my $form = shift || {};
  my $out = shift;

  unless(defined $out) {
    my $scalar = '';
    $out = \$scalar;
  }

  $self->template->process($step_filename, $form, $out) || die "Template error: " . $self->template->error();
  #my $return = '';
  #$self->template->process($out, $form, \$return) || die $self->template->error();
  return ref $out ? $out : \$out;
}

sub step_with_extension {
  my $self = shift;
  my $step = shift;
  my $extension_type = shift;
  my $extension = $self->{"${extension_type}_extension"};

  return ($step =~ /\.\w+$/) ? $step : "$step.$extension";
}

sub template {
  require Template;
  my $self = shift;
  unless($self->{template}) {
    $self->{template} = Template->new({
      INCLUDE_PATH => $self->include_path,
    });
  }
  return $self->{template};
}

sub record_mail_print {
  my $self = shift;
  my $step = shift;
  my $printed_mail = $self->session->{printed_mail} || [];
  unless($step && $printed_mail->[-1] && $step eq $printed_mail->[-1]) {
    push @{$printed_mail}, $step;
    $self->session({
      printed_mail => $printed_mail,
    });
  }
}

sub record_page_print {
  my $self = shift;
  my $step = shift || $self->{this_step}{this_step};
  my $printed_pages = $self->session->{_printed_pages} || [];
  unless($step && $printed_pages->[-1] && $step eq $printed_pages->[-1]) {
    push @{$printed_pages}, $step;
    $self->session({
      _printed_pages => $printed_pages,
    });
  }
}

# This subroutine will generate a generic HTML page 
# with form fields for the required fields based on the validate file
sub create_page {
  my $self = shift;
  my $step = shift;

  my $form_name = $self->{form_name} || die "need a form name";

  $self->{create_page} ||= {};
  my $interpolate_hash = {
    full_step => $self->my_content . "/" . $self->{this_step}{this_step},
    form_name => $form_name,
  };
  $self->{create_page}{header} ||= <<HEADER;
<!-- this step nicely created: [% full_step %]-->
<HTML>
<HEAD>
<TITLE> created step: [% full_step %]</TITLE>
</HEAD>
<BODY>
HEADER

  my $validate_ref = $self->get_validate_ref($self->{this_step}{this_step});
  die "couldn't get validate_ref to create_page with" unless($validate_ref);

  $interpolate_hash->{validating_keys} = [];
  for my $name ( @{$self->get_validating_keys($validate_ref)}) {
    my $hash = {
      name => $name,
    };
    push @{$interpolate_hash->{validating_keys}}, $hash;
    #$content .= "[form.$name"."_required]";
    #$content .= "[|| form.$name"."_error env.blank]";
  }

  $self->{create_page}{js} ||= $self->generate_js_validation($validate_ref);
  $self->{create_page}{table_open} ||= "<TABLE>";
  $ENV{SCRIPT_NAME} ||= '';
  $ENV{PATH_INFO}   ||= '';
  $self->{create_page}{form_open} ||= "<FORM METHOD=post NAME='[% form_name %]' ACTION='$ENV{SCRIPT_NAME}$ENV{PATH_INFO}'>";
  $self->{create_page}{form} ||= <<FORM;
[% FOREACH hash = validating_keys %]
  <TR>
    <TD align=right>[% hash.name %]</TD>
    <TD><INPUT NAME='[% hash.name %]'></TD>
  </TR>
[% END %]
  <TR><TD><INPUT TYPE=submit NAME=_submit VALUE=next></TD></TR>
FORM
  $self->{create_page}{form_close} ||= "</FORM>";
  $self->{create_page}{table_close} ||= "</TABLE>";
  $self->{create_page}{footer} ||= <<FOOTER;
</BODY>
</HTML>
FOOTER

  my $content = <<CONTENT;
$self->{create_page}{header}
$self->{create_page}{form_open}
$self->{create_page}{table_open}
$self->{create_page}{form}
$self->{create_page}{table_close}
$self->{create_page}{form_close}
$self->{create_page}{footer}
$self->{create_page}{js}
CONTENT

  my $return = '';
  $self->template->process(\$content, $interpolate_hash, \$return);
  return $return;
}


sub GET_VALUES {
  my $values=shift;
  return () unless defined $values;
  if (ref $values eq "ARRAY") {
    return @$values;
  }
  return ($values);
}

sub URLEncode {
  my $arg = shift;
  my ($ref,$return) = ref($arg) ? ($arg,0) : (\$arg,1) ;

  if (ref($ref) ne 'SCALAR') {
    die "URLEncode can only modify a SCALAR ref!: ".ref($ref);
    return undef;
  }

  if ( (defined $$ref) && length $$ref) {
    $$ref =~ s/([^\w\.\-\ \@\/\:])/sprintf("%%%02X",ord($1))/eg;
    $$ref =~ y/\ /+/;
  }

  return $return ? $$ref : '';
}

sub my_content_type {
  my $self = shift;
  my $step = shift;
  unless($ENV{CONTENT_TYPED}) {
    if($step && $step =~ /\.xml/) {
      print "Content-type: text/xml\n\n";
    } else {
      print "Content-type: text/html\n\n";
    }
    $ENV{CONTENT_TYPED} = 1;
  }
}

sub location_bounce {
  my $self = shift;
  my $url = shift;
  my $referer = shift;
  if (exists $ENV{CONTENT_TYPED}) {
    print "Location: <a href='$url'>$url</a><br>\n";
  } else {
    print "Status: 302\r\n";
    print "Referer: $referer\r\n" if($referer);
    print "Location: $url\r\n\r\n";
  }
  return 1;
}

1;

__END__

=head1 NAME

CGI::Path - module to aid in traversing one or more paths

=head1 SYNOPSIS

CGI::Path allows for easy navigation through a set of steps, a path.  It uses a session extensively (managed
by default via Apache::Session) to hopefully simplify path based cgis.

=head1 A PATH

A path is a package, like CGI::Path::Skel.  The path needs to be @ISA CGI::Path.  The package can contain
the step methods as described below.  You can also make a directory for the path, 
like CGI/Path/Skel, where the direectory will contain a package for each step.  This could be done from
your $ENV{PERL5LIB}.

=head1 path_hash

The path_hash is what helps generate the path_array, which is just an array of steps.  It is a hash to 
allow for easy overrides, since it is sort of hard to override just the third element of an array 
through a simple new.

The path_hash needs a key named 'initial_step', and then steps that point down the line, like so

  path_hash => {
    initial_step => 'page_one',
    page_one     => 'page_two',
    page_two     => 'page_three',
  },

since page_three doesn't point anywhere, the path_array ends.  You can just override $self->path_hash,
and have it return a hash ref as above.

=head1 path_array

The path_array is formed from path_hash.  It is an array ref of the steps in the path.

=head1 my_module

my_module by default is something like CGI::Path::Skel.  You can override $self->my_module and have it
return a scalar containing your my_module.  Module overrides are done based on my_module.

=head1 my_content

my_module by default is something like path/skel.  It defaults to a variant of my_module.  You can
override $self->my_content and have it return a scalar your my_content.  html content gets printed based
on my_content.

=head1 include_path

include_path is a method that returns the include_path to look through for files.  I suggest returning an
array ref, even if it only contains one element.

=head1 navigate

$self->navigate walks through a path of steps, where each step corresponds to a .htm content
file and a .val validation hash.

A step corresponds to a .htm content file.  The .htm and .val need to share the base same name.

$self->{this_step} is hash ref containing the following

  previous_step => the last step
  this_step     => the current step
  validate_ref  => the validation ref for the current step

Generally, navigate generates the form (see below), and for each step does the following

  --  Get the validate ref (val_ref) for the given page
  --  Comparing the val_ref to the form see if info exists for the step
  --  Validate according to the val_ref
  --  If validation fails, or if info doesn't exist, process the page and stop

More specifically, the following methods can be called for a step, in the given order.

step                    details/possible uses
---------------------------------------------
  ${step}_hook_pre        initializations, must return 1 
                          or step gets skipped
  info_exists             checks to see if you have info 
                          for this step
  ${step}_info_complete   can be used to make sure you 
                          have all the info you need

  validate                contains the following
  ${step}_pre_validate    stuff to check before validate proper
  validate_proper         runs the .val file validation
  ${step}_post_validate   stuff to run after validate proper

  ${step}_hash_fill       return a hash ref of things to add to $self->fill
                          fill is a hash ref of what fills the forms
  ${step}_hash_form       perhaps set stuff for $self->{my_form}
                          my_form is a hash ref that gets passed to the process method
  ${step}_hash_errors     set errors
  ${step}_step            do actual stuff for the step
  ${step}_hook_post       last chance

=head1 VALIDATION

The three validation methods mentioned above in navigate (pre, proper, post) handle validation.  The pre and post
methods are hooks so you could do whatever custom validation you like.  By default, validate_proper is handled by
CGI::Ex::Validate.  See the L<CGI::Ex::Validate> for details.  If any of the three methods find validation errors
 for a given page, that page is displayed.  If the page was immediately shown before, errors are passed to the page.

=head1 .val files
By default, .val files are turned into refs by YAML.  See the L<YAML> for details.  This could easily be changed by 
writing your own conf_read method, which takes the full path to a file and returns a ref.  The ref that gets returned
 needs to nicely match the structure required by validate_proper.

=head1 JAVASCRIPT VALIDATION

Javascript validation is generated by generate_js_validation based on the .val ref.  generate_js_validation uses
CGI::Ex::Validate by default.  See the L<CGI::Ex::Validate> for details.  You need to put a js_validation tag on 
your page to get the validation.  The form name is MYFORM by default, but can be changed by setting $self->{form_name}.

=head1 generate_form

The goal is that the programmer just look at $self->form for form or session information.  
To help facilitate this goal, I use the following

  $self->this_form           - form from the current hit
  $self->{session_only} = [] - things that get deleted from this_form and get inserted from the session
  $self->{session_wins} = [] - this_form wins by default, set this if you want something just from the session

The code then sets the form with the following line

  $self->{form} = {%{$self->session}, %{$this_form}, %{$form}};

=head1 Session management

CGI::Path uses Apache::Session::File by default for session management.  If you use this default you will need to write the following methods

  session_dir      - returns the directory where the session files will go
  session_lock_dir - returns the directory where the session lock files will go

One failing of Apache::Session::File is it not working so hot over NFS.  Sorry, patches were not readily accepted.

=head1 magic_fill

magic_fill is written to help aid in rapid development.  It is a simple, space-delimited file of key/value pairs, like so

  address                       123 Fake Street
  email,email_address,from      cpan@spack.net

I split on the first white space, then split on commas for the key names.  In the above example, I would end up with a ref like this

  {
    address       => '123 Fake Street',
    email         => 'cpan@spack.net',
    email_address => 'cpan@spack.net',
    from          => 'cpan@spack.net',
  }

Once I have a ref, those values will get filled into forms as pages are displayed.  Makes it nice to fill forms with dummy data and test the
flow of your script.

magic_fill is turned off by default.  The method allow_magic_fill determines if magic_fill is on.  By default, allow_magic_fill just looks at
$self->{allow_magic_fill} and returns true or false accordingly.  magic_fill_filename points to the location of your file.

When you new up your CGI::Path object you just need to do something like the following

my $self = CGI::Path->new({
  allow_magic_fill      => 1,
  magic_fill_filename   => "/path/to/magic_fill_file",
});

You can use variable values using the magic_fill_interpolation_hash.  By default, you can use Template::Toolkit tags, like so

currenttime            [% localtime %]

Currently, the following are included by default in the magic_fill_interpolation_hash

  script    - a good guess at the name of your script
  _script   - the stuff after the last _ in the above script
  localtime - scalar (localtime),
  time      - time,

I also include %ENV

Two other keys are not available by default, based on micro seconds namely

  micro      - join(".", &Time::HiRes::gettimeofday()), which really tries to get you a unique value
  micro_part - (&Time::HiRes::gettimeofday())[1];, which is just the micro seconds

To make these swaps available you need to set $self->{allow_magic_micro} to a true value.

=head1 allow_history

At least partly due to the sometimes complicated nature of paths, I have found it difficult to debug what is 
actually going on during navigation.  The history features of CGI::Path aim to try and make things a little 
easier to follow.  The goal is for each step to get added to the history and get spit out to a popup window,
showing in hopefully easy to read fashion, what happened that led to the step being printed.

To turn on the history features, the allow_history method needs to return true.  The default method checks to see
that both $self->{allow_history} and $self->form->{$self->{history_key}} are true.  The default history_key is named
history.   When CGI::Path finds that history is allowed $self->{history_key} gets saved to the session, which means
the history window will pop up for each step so long as you stay in the session, and don't stop allowing history.

This is a rather new feature and I have now likely missed adding history to a few steps.  Please let me know where
other history might be useful.

=head1 OBJECT KEYS

Here is a listing of some keys in the object, listed with default values.

  ### turn on keeping history, $self->form->{$self->{history_key}} also needs to be true
  allow_history         => 0,
  ### history_key is the key from the form to turn on history
  history_key           => 'history',

  ### turn on magic fill
  allow_magic_fill      => 0,
  ### turn on micro seconds, which requires Time::HiRes
  allow_magic_micro     => 0,
  ### full path to the magic_fill file
  magic_fill_filename   => '',

  ### if a given page doesn't exist, create it using create_page method
  create_page           => 0,

  ### form_name is used for javascript
  form_name             => 'MYFORM',

  ### extension for htm files
  htm_extension         => 'htm',
  ### extension for validation files 
  val_extension         => 'val',

  ### if the user submits an empty form, keep the session
  keep_no_form_session  => 0,

  ### 'fake keys', stuff that gets skipped from the session
  not_a_real_key        => [qw(_begin_time _http_referer _printed_pages _session_id _submit _validated)],

  ### sort of a linked list of the path
  path_hash             => {
#      simple example
#      initial_step       => 'page1',
#      page1              => 'page2',
#      page2              => 'page3',
#      page3              => '',
  },

  ### used for requiring in files
  perl5lib              => $ENV{PERL5LIB} || '',

  ### only get these values from the session
  session_only          => ['_validated'],
  ### if these values are in the session and form, the session wins
  session_wins          => [],
  ### sometimes you might not want to use a session
  use_session           => 1,

  ### what got validated on this request
  validated_fresh       => {},

  ### a history of bless'ings
  WASA                  => [],

=head1 handle_jump_around

handle_jump_around tries to handle when users jump around.  Like when they get to the third
page, then jump back to the first page and resubmit something there.  handle_jump_around would
hopefully figure out that the user just submitted the first page, so the path gets set back there.
handle_jump_around then looks through the validation refs for subsequent pages and wipes all the keys
that are marked with WipeOnBack.  This allows you to wipe enough keys so the pages will be redisplayed,
but the user's information doesn't need to all get re-entered.  

I have used keys such as enter_info_submitted, a hidden key on the enter_info page as a WipeOnBack key.  
Then, if the user submits a page before enter_info, the enter_info_submitted key gets wiped and consequently 
the enter_info page gets redisplayed, but with all the user's info still entered.

=head1 handle_unvalidated_keys

handle_unvalidated_keys looks through the generated form for keys that haven't yet been validated.  If
handle_unvalidated_keys finds a key that is in a subsequent validation ref, it will save it.  This allows
for bouncing into a cgi with all the information to get to say the receipt page, without show the all
the pages.

=head1 MULTIPLE PATHS

It is quite easy to look at $ENV{PATH_INFO} and control multiple paths through a single cgi.  I offer the
following as a simple example

sub path_hash {
  my $self = shift;
  my $sub_path = '';
  if($ENV{PATH_INFO} && $ENV{PATH_INFO} =~ m@/(\w+)@) {
    $sub_path = $1;
  }
  my $sub_path_hash = {
    '' => {
      initial_step => 'main',
      main         => '',
    },
  };

  ### this is the generic path for adding something
  if($sub_path =~ /^add_(\w+)$/ && !exists $sub_path_hash->{$sub_path}) {
    $sub_path_hash->{$sub_path} = {
      initial_step          => $sub_path,
      $sub_path             => "${sub_path}_confirm",
      "${sub_path}_confirm" => "${sub_path}_receipt",
    };
  }
  $sub_path = '' unless(exists $sub_path_hash->{$sub_path});
  return $sub_path_hash->{$sub_path};
}

The above path_hash method was used to manage a series of distinct add paths.  Distinct paths added users,
categories, blogs and entries.  Each path was to handled differently, but they each had a path similar to the
add_user path, which looked like this

add_user => add_user_confirm => add_user_receipt

=head1 APOLOGIES

This system is based on one that has been used to write some rather intense cgis, responsible
for lots of pressure, traffic and dollars.  That said, CGI::Path is still in sort of alpha stages,
where I am still trying to get everything in its right place.  That has been harder than I had hoped.
It is also based heavily on CGI::Ex, also newly open sourced, but based on I feel, steady technology.
I am hoping to one day soon get a nice, easy to follow example of a three step path that allows a 
user to enter information, confirm the information and then send an email.  But for now, I am just
trying to get everything working.  The docs should improve in time.

=head1 VISION

Keeping the above APOLOGIES in mind, I think CGI::Path could change how the Perl world writes cgis.  I have
begun to use it for even doing two page paths.  Not having to worry about navigation, validation and the
like has been oh so nice.  Once the navigation method is understood, a programmer just ties in where he
needs to, and writes little else.  The cgi mailer described above would require writing the htm, .val files,
and the methods to actually send the email.

=head1 AUTHOR

Copyright 2003-2004, Earl J. Cahill.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: cpan@spack.net.

When sending bug reports, please provide the version of CGI::Path, the version of Perl, and the name and version of the operating
system you are using.

=cut
