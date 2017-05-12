#
# Data::Shark::DIO.pm
#
# Copyright (C) 2007 William Walz. All Rights Reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Data::Shark::DIO;

use version; our $VERSION = qv('2.2');

use strict;
use base qw( Exporter );

use Cache::FileCache;

our @EXPORT      = qw( );
our @EXPORT_OK   = qw( );
our %EXPORT_TAGS = ( );

my %sys_config = (
  'dbi_func' => 'Data::Shark::sDIO::sdbi()',
  'dio_ns'   => 'Data::Shark',  # do not change, hardcoded below
);

my %sys_list = (
 'sDIO' => {
  'get_dios' => {
      'cd_type'       => 'DBI',
      'cd_stmt'       => 'select cd_id, cd_namespace, cd_name, cd_version, cd_sysclass, cd_type, cd_return, cd_cache, cd_stmt, cd_stmt_noarg, cd_profile, cd_repl, cd_action, cd_audit from core_dio order by cd_namespace, cd_name, cd_version',
      'out_keys'   => { 'cd_id' => {pos => 0}, 'cd_namespace' => {pos => 1}, 'cd_name' => {pos => 2}, 'cd_version' => {pos => 3}, 'cd_sysclass' => {pos => 4}, 'cd_type' => {pos => 5}, 'cd_return' => {pos => 6}, 'cd_cache' => {pos => 7}, 'cd_stmt' => {pos => 8}, 'cd_stmt_noarg' => {pos => 9}, 'cd_profile' => {'pos' => 10}, 'cd_repl' => {'pos' => 11}, 'cd_action' => {'pos' => 12}, 'cd_audit' => {'pos' => 13} },
      'cd_return'     => 'arrayofhash',
  },
  'get_inkeys' => {
      'cd_type'       => 'DBI',
      'cd_stmt'       => "select ci_pos,ci_name,ci_req,ci_default,ci_key,ci_opt from core_dio_inkey where ci_cd_id = ? order by ci_pos asc",
      'in_keys'    => { 0 => {name => 'cd_id', default => 0} },
      'out_keys'   => { name => {pos => 1}, pos => {pos => 0}, req => {pos => 2}, default => {pos => 3}, 'key' => {pos => 4}, 'opt' => {pos => 5}, },
      'cd_return'     => 'hashofhash',
  },
  'get_outkeys' => {
      'cd_type'       => 'DBI',
      'cd_stmt'       => "select co_name,co_pos,co_default,co_key from core_dio_outkey where co_cd_id = ? order by co_pos asc",
      'in_keys'    => { 0 => {name => 'cd_id', default => 0} },
      'out_keys'   => { name => {pos => 0}, pos => {pos => 1}, default => {pos => 2}, 'key' => {pos => 3} },
      'cd_return'     => 'hashofhash',
  },
  'get_exps' => {
      'cd_type'       => 'DBI',
      'cd_stmt'       => "select cd_name, cd_namespace from core_dio, core_dio_cache_exp where ce_cd_id = ? and cd_id = ce_exp_id order by cd_namespace, cd_name",
      'in_keys'    => { 0 => {name => 'cd_id', default => 0} },
      'out_keys'   => { name => {pos => 0}, namespace => {pos => 1} },
      'cd_return'     => 'hashofhash',
  },
 },
);

sub _re_init {
  AlbacoreW::DIO::_init_dbi({'dbi_func' => 'AlbacoreW::Data::sdbi()','file_name' => '/usr/local/albacore/Albacore/Vino' });
}

sub _expire {
  my ($dio_id) = @_;
  my $dio = AlbacoreW::DIO::get_dio({cd_id => $dio_id});
  $AlbacoreW::_Profile = $AlbacoreW::_Profile || new Cache::FileCache( {'namespace' => 'wdio_profile'});
  my $cf;
  $cf = '*' if $dio->{'cd_cache'} eq 'F';
  my $c = $AlbacoreW::_Profile->remove($dio->{'cd_namespace'} . ',' . $dio->{'cd_name'} . $cf);
}

sub _expire_all {
  $AlbacoreW::_Profile = $AlbacoreW::_Profile || new Cache::FileCache( {'namespace' => 'wdio_profile'});
  $AlbacoreW::_Profile->clear();
}

sub _profile {
  my ($dio_id, $onoff) = @_;
  AlbacoreW::DIO::profile_on ({cd_id => $dio_id}) if $onoff;
  AlbacoreW::DIO::profile_off({cd_id => $dio_id}) if !$onoff;
}

sub init_memory_dbi {
  my ($config) = @_;

  # overide default dbi_func
  $sys_config{'dbi_func'} = $config->{'dbi_func'}
    if exists $config->{'dbi_func'};

  # grab config and list
  my ($run_config, $run_list);

  $run_config = $config->{'config'} if exists $config->{'config'};
  $run_list   = $config->{'list'}   if exists $config->{'list'};
  
  # first build core dios in memory
  _init($run_config, $run_list, {}) if defined $run_list;
}

sub init_dbi {
  my ($config) = @_;

  # overide default dbi_func
  $sys_config{'dbi_func'} = $config->{'dbi_func'}
    if exists $config->{'dbi_func'};

  # first build core dios in memory
  _init(\%sys_config, \%sys_list, {});

  # build the hash then pass to _init
  my %dio_list;
  my $dios = Data::Shark::D_sDIO::get_dios();
  foreach my $dioh (@{ $dios }) {
    foreach my $k (keys %{ $dioh }) {
      $dio_list{$dioh->{'cd_namespace'}}{$dioh->{'cd_name'}}{$k} = $dioh->{$k};
    }
    # in keys
    my $in_keys = Data::Shark::D_sDIO::get_inkeys({'cd_id' => $dioh->{'cd_id'}});
    $in_keys && do {
      my %t;
      foreach my $k (keys %{ $in_keys }) {
        $t{$k} = $in_keys->{$k};
      }
      $dio_list{$dioh->{'cd_namespace'}}{$dioh->{'cd_name'}}{'in_keys'} = \%t;
    };
    # out keys
    my $out_keys = Data::Shark::D_sDIO::get_outkeys({'cd_id' => $dioh->{'cd_id'}});
    $out_keys && do {
      my %t;
      foreach my $k (keys %{ $out_keys }) {
        $t{$k} = $out_keys->{$k};
      }
      $dio_list{$dioh->{'cd_namespace'}}{$dioh->{'cd_name'}}{'out_keys'} = \%t;
    };
    # exps
    my $exps = Data::Shark::D_sDIO::get_exps({'cd_id' => $dioh->{'cd_id'}});
    $exps && do {
      my %t;
      foreach my $k (keys %{ $exps }) {
        $t{$k} = $exps->{$k};
      }
      $dio_list{$dioh->{'cd_namespace'}}{$dioh->{'cd_name'}}{'exps'} = \%t;
    };
  }
  # now pass
  _init($config, \%dio_list);
}

sub _init {
  my ($config, $dio_list) = @_;

  my ($file_name, $verbose, $debug, $profile, $audit) = ('',0,0,0,'');

  $debug   = 1 if exists $config->{'debug'};
  $profile = 1 if exists $config->{'profile'};
  $verbose = 1 if exists $config->{'verbose'};

  my $ns = ((defined $config->{'name_space'}) && $config->{'name_space'} ne '') ? $config->{'name_space'} : 'Data::Shark';

  $file_name = $config->{'file_name'} if (defined $config->{'file_name'}) && $config->{'file_name'};

  open(OUT_FILE, "> $file_name" . 't') || die "cannot open $file_name ($!)" if $file_name;

  # check if we need SQL::Abstract
  foreach my $dions (keys %{ $dio_list }) {
    foreach my $diotag (keys %{ $dio_list->{$dions} }) {
      my $dioh = $dio_list->{$dions}{$diotag};
      if ($dioh->{'cd_type'} eq 'SQL::Abstract') {
        print OUT_FILE 'use SQL::Abstract;', "\n";
        last;
      }
    }
  }

  # loop and build
  foreach my $dions (sort {$a cmp $b} keys %{ $dio_list }) {
    foreach my $diotag (sort {$a cmp $b} keys %{ $dio_list->{$dions} }) {
    my $dioh = $dio_list->{$dions}{$diotag};
    my ($p_tag,$c_tag, $stmt, $pstmt, $in_keys, $out_keys, $exps);

    $dioh->{'cd_sysclass'}   = '' unless defined $dioh->{'cd_sysclass'};
    $dioh->{'cd_return'}     = '' unless defined $dioh->{'cd_return'};
    $dioh->{'cd_cache'}      = '' unless defined $dioh->{'cd_cache'};
    $dioh->{'cd_stmt'}       = '' unless defined $dioh->{'cd_stmt'};
    $dioh->{'cd_profile'}    = '' unless defined $dioh->{'cd_profile'};
    $dioh->{'cd_repl'}       = '' unless defined $dioh->{'cd_repl'};
    $dioh->{'cd_action'}     = '' unless defined $dioh->{'cd_action'};
    $dioh->{'cd_audit'}      = '' unless defined $dioh->{'cd_audit'};
    $dioh->{'cd_type'}       = '' unless defined $dioh->{'cd_type'};

    # skip Iter type and others, added at end
    next if ($dioh->{'cd_type'} eq 'DBI-Iter' || $dioh->{'cd_type'} eq 'DBI-Factory' || $dioh->{'cd_type'} eq 'DBI-Factory-Prep');

    $profile = $dioh->{'cd_profile'} eq '1' ? 1 : 0;

    $audit = $dioh->{'cd_audit'};

    print "dbi->dio( D_$dions, $diotag )\n";

    $in_keys  = \%{$dioh->{'in_keys'}} if exists $dioh->{'in_keys'};
    $out_keys = \%{$dioh->{'out_keys'}} if exists $dioh->{'out_keys'};
    $exps     = \%{$dioh->{'exps'}} if exists $dioh->{'exps'};

    if ($dioh->{'cd_cache'} eq 'F') {
      # setup global cache pointer
      $c_tag =  $ns . '::D_' . $dions . '::' . $diotag . '_fc';
    }
    $profile && do {
      # setup global profile pointer
      $p_tag =  $ns . '::_Profile';
    };
    $stmt .= 'sub ' . $ns . '::D_' . $dions . '::' . $diotag . ' {' . "\n";
    if ($in_keys) {
      $stmt .= '  my ($args) = @_;' . "\n";
      $stmt .= '  my $argc = scalar keys %{ $args };' . "\n\n" if $dioh->{'cd_stmt_noarg'};
      # process defaults first
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= '  $args->{\'' . $k->{'name'} . '\'} = $args->{\'' . $k->{'name'} . '\'} || q{' . $k->{'default'} . '};' . "\n" if (defined $k->{'default'}) && $k->{'default'} ne '' && $k->{'opt'} eq 'use_default';
      }
      # now do required fields
      $stmt .= '  return if 0';
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= ' || $args->{\''. $k->{'name'} . '\'} eq ""' if (defined $k->{'req'}) && $k->{'req'} eq '1';
      }
      $stmt .= ';' . "\n";
    } else {
      $stmt .= '  my ($args) = @_;' . "\n" if $dioh->{'cd_type'} eq 'SQL::Abstract';
    }

    # initial audit section
    $audit =~ /[ADB]/ && do {
      $stmt .= "\n" . '  my $ca_id = ' . $ns . '::D_DIO::dio_audit_insert({ca_id => 0,ca_cd_id => ' . $dioh->{'cd_id'} . ',ca_ip => Apache->request->connection->remote_ip,user => $args->{\'user\'}});' . "\n\n";
    };

    # add inkeys for audit if requested
    $audit =~ /[DB]/ && $in_keys && do {
      foreach my $k (keys %{ $in_keys }) {
        $stmt .= '  ' . $ns . '::D_DIO::dio_audit_inkey({ci_ca_id => $ca_id, ci_pos => ' . $k . ', ci_tag => \'' . $in_keys->{$k}{'name'} . '\', ci_value => $args{\'' . $in_keys->{$k}{'name'} . '\'}});' . "\n\n";
      }
    };

    # profile section
    $profile && do {
      $stmt .= '  $' . $p_tag . ' = $' . $p_tag . ' || new Cache::FileCache( {\'namespace\' => \'' . $ns . '_dio_profile\'});' . "\n";
      my $cf = '';
      $cf = '*' if $dioh->{'cd_cache'} eq 'F';
      $stmt .= '  my $pkey = \'' . $diotag . '\';' . "\n";
      if ($in_keys) {
        foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
          $stmt .= '  $pkey .= \', \' . $args->{\'' . $k->{'name'} . '\'};' . "\n" if $k->{'name'};
        } 
      }
      $stmt .= '  my $pdata = $' . $p_tag . '->get(\'' . $dions . ',' . $diotag . $cf . '\');' . "\n";
      $stmt .= '  my $t = time();' . "\n";
      $stmt .= '  push @{ $pdata->{\'args\'}{$t} }, $pkey;' . "\n";
      $pstmt = '  push @{ $pdata->{\'time\'}{$t} }, time();' . "\n";
      $pstmt .= '  $' . $p_tag . '->set(\'' . $dions . ',' . $diotag . $cf . '\',$pdata);' . "\n";  
    };

    # cache exp section
    if ($exps) {
      $stmt .= '  my $c;' . "\n";
      # expire dependent keys
      foreach my $k (keys %{ $exps }) {
#        if (ref($dio_list->{$diotag}{'cache_exp'}{$k}) eq 'REF') {
#
#        } else {
          $stmt .= '  $c = new Cache::FileCache({\'namespace\' => \'' . $ns . '_' . $exps->{$k}{'namespace'} . '.' . $k .'\'});' . "\n";
          $stmt .= '  $c->clear() if $c;' . "\n";
#        }
      }
    }
    # cache section
    if ($dioh->{'cd_cache'} eq 'F') {
      # clear existing cache on startup
      my $tc = new Cache::FileCache({'namespace' => $ns . '_' . $dions . '.' . $diotag});
      $tc->clear() if !$debug;
      # setup cache
      $stmt .= '  $' . $c_tag . ' = $' . $c_tag . ' || new Cache::FileCache( {\'namespace\' => \'' . $ns . '_' . $dions . '.' . $diotag . '\'});' . "\n";
      $stmt .= '  my $hkey = \'' . $diotag . '\';' . "\n";
      if ($in_keys) {
        foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
          $stmt .= '  $hkey .= $args->{\'' . $k->{'name'} . '\'};' . "\n" if $k->{'name'};
        } 
      }
      $stmt .= '  my $cdata = $' . $c_tag . '->get($hkey);' . "\n";
      $stmt .= 'if ($cdata) { ' . $pstmt . '}' . "\n" if $profile;
      $stmt .= '  return $cdata if $cdata;' . "\n";
    }
    $stmt .= '  my $dbi = ' . $config->{'dbi_func'} . ';' . "\n"; 
    $stmt .= '  my $sth;' . "\n\n";

    # process input
    for ($dioh->{'cd_type'}) {
      /^DBI$/ && do {
        if ($in_keys) {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  my $sql = q{' . $dioh->{'cd_stmt'} . '};' . "\n";
          # check for tag based in keys
          my $have_tags = 0;
          foreach my $k (@{ $in_keys }{ keys %{ $in_keys } }) {
            if ($k->{'opt'} eq 'tag_based') {
              unless ($have_tags) {
                $stmt .= '  my %tag_hash;' . "\n";
                $have_tags = 1;
              }
              $k->{'default'} =~ s/[\r\n]/ /g;
              $stmt .= '  if (exists $args->{\'' . $k->{'name'} . '\'} && $args->{\'' . $k->{'name'} . '\'} ne \'\') {' . "\n";
              $stmt .= '    $sql =~ s/:' . $k->{'name'} . '/' . $k->{'default'} . '/;' . "\n"; 
              # check for placeholders
              if ($k->{'default'} =~ /:placeholders/) {
                $stmt .= '    if (ref $args->{\'' . $k->{'name'} . '\'} eq \'ARRAY\') {' . "\n";
                $stmt .= '      $tag_hash{' . $k->{'name'} . '} = $args->{\'' . $k->{'name'} . '\'};' . "\n";
                $stmt .= '    } else {' . "\n";
                $stmt .= '      $tag_hash{' . $k->{'name'} . '} = [$args->{\'' . $k->{'name'} . '\'}];' . "\n";
                $stmt .= '    }' . "\n";
                $stmt .= '    my $placeholders = join(\', \', map { \'?\' } @{$tag_hash{' . $k->{'name'} . '}});' . "\n";
                $stmt .= '    $sql =~ s/' . $k->{'name'} . ':placeholders/$placeholders/;' . "\n"; 
              } else {
                if (index($k->{'default'}, '?') >= 0) {
                  $stmt .= '    if (ref $args->{\'' . $k->{'name'} . '\'} eq \'ARRAY\') {' . "\n";
                  $stmt .= '      $tag_hash{' . $k->{'name'} . '} = $args->{\'' . $k->{'name'} . '\'};' . "\n";
                  $stmt .= '    } else {' . "\n";
                  $stmt .= '      $tag_hash{' . $k->{'name'} . '} = [$args->{\'' . $k->{'name'} . '\'}];' . "\n";
                  $stmt .= '    }' . "\n";
                } else {
                  $k->{'no_bind'} = 1;
                }
              }
              $stmt .= '  } else {' . "\n";
              $stmt .= '    $sql =~ s/:' . $k->{'name'} . '//;' . "\n"; 
              $stmt .= '  }' . "\n";
            }
          }
          
          my $extra = "";
          # check for limit or offset
          foreach my $k (@{ $in_keys }{ keys %{ $in_keys } }) {
            for ($k->{'name'}) {
              /^limit$/ && do { $extra .= ' limit \' . $args->{\'limit\'} . \''; last; };
              /^mysql_limit$/ && do { $extra .= ' limit \' . $args->{\'mysql_limit\'} . \''; last; };
              /^offset$/ && do { $extra .= ' offset \' . $args->{\'offset\'} . \''; last; };
            }
          }
          $stmt .= '  $sth = $dbi->db_prep($sql' . ($extra ? ' . q{' . $extra . '}' : '') . ');' . "\n";
          if ($have_tags) {
            $stmt .= '  my @binds;' . "\n";
            foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
              next if exists $k->{'no_bind'};
              if ($k->{'opt'} eq 'tag_based') {
                $stmt .= '  push @binds, @{$tag_hash{\'' . $k->{'name'} . '\'}} if exists $tag_hash{\'' . $k->{'name'} . '\'};' ."\n";
              } else {
                $stmt .= '  push @binds, $args->{\'' . $k->{'name'} . '\'};' . "\n";
              }
            }
            $stmt .= '  if (@binds) {' . "\n";
            $stmt .= '    $dbi->db_exec($sth, @binds);' . "\n";
            $stmt .= '  } else {' . "\n";
            $stmt .= '    $dbi->db_exec($sth);' . "\n";
            $stmt .= '  }' . "\n";
          } else {
            $stmt .= '  $dbi->db_exec($sth, @$args{ ';
            my @c;
            foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
              push @c, '\'' . $k->{'name'} . '\'' if $k->{'name'} !~ /(mysql_limit|limit|offset)/;
            }
            $stmt .= join(',', @c) . ' });' . "\n\n";
          }
        } else {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  $sth = $dbi->db_sql(\'' . $dioh->{'cd_stmt'} . '\');' . "\n\n";
        }
        last;
      };
      /^SQL::Abstract$/ && do {
        my $tab = $dioh->{'cd_stmt'};
        for ($tab) {s/^\s+//; s/\s+$//;}
        $stmt .= q{  my $sql   = SQL::Abstract->new;} . "\n";
        $stmt .= q{  my $table = '} . $tab . q{';} . "\n";
        for ($dioh->{'cd_action'}) {
          /^select$/ && do {
            # check for inkeys defined
            if ($in_keys) {
              $stmt .= '  my $fields;' . "\n";
              # allow passed fields tag to override inkeys
              $stmt .= '  if ((defined $args->{\'fields\'})) {' . "\n";
              $stmt .= '    $fields = $args->{\'fields\'};' . "\n";
              $stmt .= '  } else {' . "\n";
              $stmt .= '    my @select = ( ';
              my @c;
              foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
                push @c, '\'' . $k->{'name'} . '\'' if $k->{'name'} !~ /(where|order|fields)/;
              }
              $stmt .= join(',', @c) . ' );' . "\n";
              $stmt .= '    $fields = \@select;' . "\n";
              $stmt .= '  }' . "\n";
            } else {
              $stmt .= '  my $fields = ((defined $args->{\'fields\'})?$args->{\'fields\'}:undef);' . "\n";
            }
            $stmt .= q{  my ($stmt,@bind) = $sql->select($table,$fields,((defined $args->{'where'})?$args->{'where'}:undef),((defined $args->{'order'})?$args->{'order'}:undef));} . "\n";
            $stmt .= q{  $sth = $dbi->db_prep($stmt);} . "\n";
            $stmt .= q{  $dbi->db_exec($sth, @bind);} . "\n";
            last;
          };
          /^insert$/ && do {
            $stmt .= q{  my $vals = undef;} . "\n";
            $stmt .= q{  $vals = $args->{'fieldvals'} if defined $args->{'fieldvals'};} . "\n";
            $stmt .= q{  $vals = $args->{'values'} if defined $args->{'values'};} . "\n";
            $stmt .= q{  my ($stmt,@bind) = $sql->insert($table,$vals);} . "\n";
            $stmt .= q{  $sth = $dbi->db_prep($stmt);} . "\n";
            $stmt .= q{  $dbi->db_exec($sth, @bind);} . "\n";
            last;
          };
          /^udpate$/ && do {
            $stmt .= q{  my ($stmt,@bind) = $sql->update($table,((defined $args->{'fieldvals'})?$args->{'fieldvals'}:undef),((defined $args->{'where'})?$args->{'where'}:undef));} . "\n";
            $stmt .= q{  $sth = $dbi->db_prep($stmt);} . "\n";
            $stmt .= q{  $dbi->db_exec($sth, @bind);} . "\n";
            last;
          };
          /^delete$/ && do {
            $stmt .= q{  my ($stmt,@bind) = $sql->delete($table,((defined $args->{'where'})?$args->{'where'}:undef));} . "\n";
            $stmt .= q{  $sth = $dbi->db_prep($stmt);} . "\n";
            $stmt .= q{  $dbi->db_exec($sth, @bind);} . "\n";
            last;
          };
        }
        last;
      };
    }

    # setup return type
    for ($dioh->{'cd_return'}) {
      /^array$/ && do {
        $stmt .= '  if ($argc) {' . "\n" if $dioh->{'cd_stmt_noarg'};
        $stmt .= '    my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '    $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, \@d);' . "\n";
        }
        $stmt .= '    return \@d;' . "\n";
        if ($dioh->{'cd_stmt_noarg'}) {
          $stmt .= '  } else {' . "\n";
          $stmt .= '    my $items = [];' . "\n";
          $stmt .= '    while(my @d = $dbi->db_fetch($sth)) {' . "\n";
          $stmt .= '      push @{$items}, [@d];' . "\n";
          $stmt .= '    }' . "\n";
          $stmt .= '    $dbi->db_done($sth);' . "\n";
          if ($dioh->{'cd_cache'} eq 'F') {
            $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
          }
          $stmt .= $pstmt if $profile;
          $stmt .= '    return $items;' . "\n";
          $stmt .= '  }' . "\n";
        }
        $stmt .= '}' . "\n";
        last;
      };
      /^arrayofscalar$/ && do {
        $stmt .= '  my $items = [];' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    push @{$items}, $d[0];' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '  $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^arrayofarray$/ && do {
        $stmt .= '  my $items = [];' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    push @{$items}, [@d];' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '  $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^none$/ && do {
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        $stmt .= $pstmt if $profile;
        $stmt .= '}' . "\n";
        last;
      };
      /^scalar$/ && do {
        $stmt .= '  my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '  $' . $c_tag . '->set($hkey, $d[0]);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $d[0];' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^hash$/ && do {
        $stmt .= '  if ($argc) {' . "\n" if ($dioh->{'cd_stmt_noarg'});
        $stmt .= '    my $out_h;' . "\n";
        $stmt .= '    my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '    $dbi->db_done($sth);' . "\n";
        my $kc =  scalar keys %{ $out_keys };
        $stmt .= '    @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
        my @c;
        foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'};}
        $stmt .= join(',',@c) . '];' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, $out_h);' . "\n";
        }
          $stmt .= $pstmt if $profile;
        $stmt .= '    return $out_h;' . "\n";
        if ($dioh->{'cd_stmt_noarg'}) {
          $stmt .= '  } else {' . "\n";
          $stmt .= '    my $items;' . "\n";
          $stmt .= '    while(my @d = $dbi->db_fetch($sth)) {' . "\n";
          $stmt .= '      my $out_h;' . "\n";
          my $kc =  scalar keys %{ $out_keys };
          $stmt .= '      @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
          my @c;
          foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'}; }
          $stmt .= join(',',@c) . '];' . "\n";
          $stmt .= '      push @{$items}, $out_h;' . "\n";
          $stmt .= '    }' . "\n";
          $stmt .= '    $dbi->db_done($sth);' . "\n";
          if ($dioh->{'cd_cache'} eq 'F') {
            $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
          }
          $stmt .= $pstmt if $profile;
          $stmt .= '    return $items;' . "\n";
          $stmt .= '  }' . "\n";
        }
        $stmt .= '}' . "\n";
        last;
      };
      /^arrayofhash$/ && do {
        $stmt .= '  my $items;' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    my $out_h;' . "\n";
        my $kc =  scalar keys %{ $out_keys };
        $stmt .= '    @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
        my @c;
        foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'}; }
        $stmt .= join(',',@c) . '];' . "\n";
        $stmt .= '    push @{$items}, $out_h;' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^hashofhash$/ && do {
        $stmt .= '  my $items;' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    my $out_h;' . "\n";
        my $kc =  scalar keys %{ $out_keys };
        $stmt .= '    @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
        my @c;
        foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'}; }
        $stmt .= join(',',@c) . '];' . "\n";
        $stmt .= '    $items->{$d[0]} = $out_h;' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^hashofarray$/ && do {
        $stmt .= '  my $items;' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    push @{ $items->{$d[0]} }, [@d];' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^hashofscalar$/ && do {
        $stmt .= '  my $items;' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    push @{ $items->{$d[0]} }, $d[1];' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        if ($dioh->{'cd_cache'} eq 'F') {
          $stmt .= '    $' . $c_tag . '->set($hkey, $items);' . "\n";
        }
        $stmt .= $pstmt if $profile;
        $stmt .= '  return $items;' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      /^dropdown$/ && do {
        $stmt .= '  my @values;' . "\n";
        $stmt .= '  my %labels;' . "\n";
        $stmt .= '  while(my @d = $dbi->db_fetch($sth)) {' . "\n";
        $stmt .= '    next if (exists $labels{$d[0]});' . "\n";
        $stmt .= '    push @values, $d[0];' . "\n";
        $stmt .= '    $labels{$d[0]} = $d[1];' . "\n";
        $stmt .= '  }' . "\n";
        $stmt .= '  $dbi->db_done($sth);' . "\n";
        $stmt .= $pstmt if $profile;
        $stmt .= '  return (\@values, \%labels);' . "\n";
        $stmt .= '}' . "\n";
        last;
      };
      do {
        $stmt .= '}' . "\n";
        last;
      };
    }

    if ($file_name) {
      print OUT_FILE $stmt;
    } else {
      eval "$stmt";
      #warn $@ if $@ && $debug;
      warn $@ if $@;
    }
    print "$stmt\n" if $verbose;
  }
  }

  # loop and build (DBI-Iter Type)
  foreach my $dions (sort {$a cmp $b} keys %{ $dio_list }) {
    foreach my $diotag (sort {$a cmp $b} keys %{ $dio_list->{$dions} }) {
    my $dioh = $dio_list->{$dions}{$diotag};
    my ($p_tag,$c_tag, $stmt, $pstmt, $in_keys, $out_keys);

    $dioh->{'cd_sysclass'}   = '' unless defined $dioh->{'cd_sysclass'};
    $dioh->{'cd_return'}     = '' unless defined $dioh->{'cd_return'};
    $dioh->{'cd_cache'}      = '' unless defined $dioh->{'cd_cache'};
    $dioh->{'cd_stmt'}       = '' unless defined $dioh->{'cd_stmt'};
    $dioh->{'cd_profile'}    = '' unless defined $dioh->{'cd_profile'};
    $dioh->{'cd_repl'}       = '' unless defined $dioh->{'cd_repl'};
    $dioh->{'cd_action'}     = '' unless defined $dioh->{'cd_action'};
    $dioh->{'cd_audit'}      = '' unless defined $dioh->{'cd_audit'};
    $dioh->{'cd_type'}       = '' unless defined $dioh->{'cd_type'};

    # skip non Iter type
    next if $dioh->{'cd_type'} ne 'DBI-Iter';

    $audit = $dioh->{'cd_audit'};

    print "dbi->dio( ITER:: D_$dions, $diotag )\n";

    $in_keys  = \%{$dioh->{'in_keys'}} if exists $dioh->{'in_keys'};
    $out_keys = \%{$dioh->{'out_keys'}} if exists $dioh->{'out_keys'};

    $stmt .= 'package ' . $ns . '::D_' . $dions . '::' . $diotag . ';' . "\n";
    $stmt .= 'sub new {' . "\n";
    if ($in_keys) {
      $stmt .= '  my ($class, $args) = @_;' . "\n";
      $stmt .= '  my $argc = scalar keys %{ $args };' . "\n\n" if $dioh->{'cd_stmt_noarg'};
      # process defaults first
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= '  $args->{\'' . $k->{'name'} . '\'} = $args->{\'' . $k->{'name'} . '\'} || ' . $k->{'default'} . ';' . "\n" if (defined $k->{'default'}) && $k->{'default'} ne '';
      }
      # now do required fields
      $stmt .= '  return if 0';
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= ' || $args->{\''. $k->{'name'} . '\'} eq ""' if (defined $k->{'req'}) && $k->{'req'} eq '1';
      }
      $stmt .= ';' . "\n";
    } else {
      $stmt .= '  my ($class) = @_;' . "\n";
    }


    # initial audit section
    $audit =~ /[ADB]/ && do {
      $stmt .= "\n" . '  my $ca_id = ' . $ns . '::D_DIO::dio_audit_insert({ca_id => 0,ca_cd_id => ' . $dioh->{'cd_id'} . ',ca_ip => Apache->request->connection->remote_ip,user => $args->{\'user\'}});' . "\n\n";
    };

    # add inkeys for audit if requested
    $audit =~ /[DB]/ && $in_keys && do {
      foreach my $k (keys %{ $in_keys }) {
        $stmt .= '  ' . $ns . '::D_DIO::dio_audit_inkey({ci_ca_id => $ca_id, ci_pos => ' . $k . ', ci_tag => \'' . $in_keys->{$k}{'name'} . '\', ci_value => $args{\'' . $in_keys->{$k}{'name'} . '\'}});' . "\n\n";
      }
    };

    $stmt .= '  my $dbi = ' . $config->{'dbi_func'} . ';' . "\n"; 
    $stmt .= '  my $sth;' . "\n\n";

    # process input
    for ($dioh->{'cd_type'}) {
      /^DBI-Iter$/ && do {
        if ($in_keys) {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          my $extra = "";
          # check for limit or offset
          foreach my $k (@{ $in_keys }{ keys %{ $in_keys } }) {
            for ($k->{'name'}) {
              /^limit$/ && do { $extra .= ' limit \' . $args->{\'limit\'} . \''; last; };
              /^mysql_limit$/ && do { $extra .= ' limit \' . $args->{\'mysql_limit\'} . \''; last; };
              /^offset$/ && do { $extra .= ' offset \' . $args->{\'offset\'} . \''; last; };
            }
          }
          $stmt .= '    $sth = $dbi->db_prep(\'' . $dioh->{'cd_stmt'} . $extra . '\');' . "\n";
          $stmt .= '    $dbi->db_exec($sth, @$args{ ';
          my @c;
          foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
            push @c, '\'' . $k->{'name'} . '\'' if $k->{'name'} !~ /(mysql_limit|limit|offset)/;
          }
          $stmt .= join(',', @c) . ' });' . "\n\n";
        } else {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  $sth = $dbi->db_sql(\'' . $dioh->{'cd_stmt'} . '\');' . "\n\n";
        }
        # create object
        $stmt .= '  my $self = {' . "\n";
        $stmt .= '    \'sth\' => $sth,' . "\n";
        $stmt .= '    \'dbi\' => $dbi,' . "\n";
        $stmt .= '  };' . "\n";
        $stmt .= '  bless $self;' . "\n";
        $stmt .= '  return $self;' . "\n";
        last;
      };
    }

    # end of new
    $stmt .= '}' . "\n";

    # done func
    $stmt .= 'sub done {' . "\n";
    $stmt .= '  my ($self) = @_;' . "\n";
    $stmt .= '  $self->{\'dbi\'}->db_done($self->{\'sth\'});' . "\n";
    $stmt .= '}' . "\n";

    # iter func
    $stmt .= 'sub iter {' . "\n";
    $stmt .= '  my ($self) = @_;' . "\n";

    # setup return type
    for ($dioh->{'cd_return'}) {
      /^scalar$/ && do {
        $stmt .= '  my @d = $self->{\'dbi\'}->db_fetch($self->{\'sth\'});' . "\n";
        $stmt .= '  if (@d) {' . "\n";
        $stmt .= '    return @d;' . "\n";
        $stmt .= '  } else {' . "\n";
        $stmt .= '    $self->{\'dbi\'}->db_done($self->{\'sth\'});' . "\n";
        $stmt .= '    return;' . "\n";
        $stmt .= '  }' . "\n";
        last;
      };
      /^array$/ && do {
        $stmt .= '  my @d = $self->{\'dbi\'}->db_fetch($self->{\'sth\'});' . "\n";
        $stmt .= '  if (@d) {' . "\n";
        $stmt .= '    return \@d;' . "\n";
        $stmt .= '  } else {' . "\n";
        $stmt .= '    $self->{\'dbi\'}->db_done($self->{\'sth\'});' . "\n";
        $stmt .= '    return;' . "\n";
        $stmt .= '  }' . "\n";
        last;
      };
      /^hash$/ && do {
        $stmt .= '  my $out_h;' . "\n";
        $stmt .= '  my @d = $self->{\'dbi\'}->db_fetch($self->{\'sth\'});' . "\n";
        $stmt .= '  if (@d) {' . "\n";
        my $kc =  scalar keys %{ $out_keys };
        $stmt .= '    @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
        my @c;
        foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'};}
        $stmt .= join(',',@c) . '];' . "\n";
          $stmt .= $pstmt if $profile;
        $stmt .= '    return $out_h;' . "\n";
        $stmt .= '  } else {' . "\n";
        $stmt .= '    $self->{\'dbi\'}->db_done($self->{\'sth\'});' . "\n";
        $stmt .= '    return;' . "\n";
        $stmt .= '  }' . "\n";
        last;
      };
    }
    $stmt .= '}' . "\n";

    if ($file_name) {
      print OUT_FILE $stmt;
    } else {
      eval "$stmt";
      #warn $@ if $@ && $debug;
      warn $@ if $@;
    }
    print "$stmt\n" if $verbose;
  }
  }

  # loop and build (DBI-Factory Type)
  foreach my $dions (sort {$a cmp $b} keys %{ $dio_list }) {
    foreach my $diotag (sort {$a cmp $b} keys %{ $dio_list->{$dions} }) {
    my $dioh = $dio_list->{$dions}{$diotag};
    my ($p_tag,$c_tag, $stmt, $pstmt, $in_keys, $out_keys);

    $dioh->{'cd_sysclass'}   = '' unless defined $dioh->{'cd_sysclass'};
    $dioh->{'cd_return'}     = '' unless defined $dioh->{'cd_return'};
    $dioh->{'cd_cache'}      = '' unless defined $dioh->{'cd_cache'};
    $dioh->{'cd_stmt'}       = '' unless defined $dioh->{'cd_stmt'};
    $dioh->{'cd_profile'}    = '' unless defined $dioh->{'cd_profile'};
    $dioh->{'cd_repl'}       = '' unless defined $dioh->{'cd_repl'};
    $dioh->{'cd_action'}     = '' unless defined $dioh->{'cd_action'};
    $dioh->{'cd_audit'}      = '' unless defined $dioh->{'cd_audit'};
    $dioh->{'cd_type'}       = '' unless defined $dioh->{'cd_type'};

    # skip non Iter type
    next if $dioh->{'cd_type'} !~ /^DBI-Factory/;

    $audit = $dioh->{'cd_audit'};

    print "dbi->dio( FACTORY:: D_$dions, $diotag )\n";

    $in_keys  = \%{$dioh->{'in_keys'}} if exists $dioh->{'in_keys'};
    $out_keys = \%{$dioh->{'out_keys'}} if exists $dioh->{'out_keys'};

    # generate factory function
    $stmt .= 'sub ' . $ns . '::D_' . $dions . '::' . $diotag . ' {' . "\n";
    if ($in_keys && $dioh->{'cd_type'} ne 'DBI-Factory-Prep') {
      $stmt .= '  my ($args) = @_;' . "\n";
      $stmt .= '  my $argc = scalar keys %{ $args };' . "\n\n" if $dioh->{'cd_stmt_noarg'};
      # process defaults first
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= '  $args->{\'' . $k->{'name'} . '\'} = $args->{\'' . $k->{'name'} . '\'} || ' . $k->{'default'} . ';' . "\n" if (defined $k->{'default'}) && $k->{'default'} ne '';
      }
      # now do required fields
      $stmt .= '  return if 0';
      foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
        $stmt .= ' || $args->{\''. $k->{'name'} . '\'} eq ""' if (defined $k->{'req'}) && $k->{'req'} eq '1';
      }
      $stmt .= ';' . "\n";
    }

    # initial audit section
    $audit =~ /[ADB]/ && do {
      $stmt .= "\n" . '  my $ca_id = ' . $ns . '::D_DIO::dio_audit_insert({ca_id => 0,ca_cd_id => ' . $dioh->{'cd_id'} . ',ca_ip => Apache->request->connection->remote_ip,user => $args->{\'user\'}});' . "\n\n";
    };

    # add inkeys for audit if requested
    $audit =~ /[DB]/ && $in_keys && do {
      foreach my $k (keys %{ $in_keys }) {
        $stmt .= '  ' . $ns . '::D_DIO::dio_audit_inkey({ci_ca_id => $ca_id, ci_pos => ' . $k . ', ci_tag => \'' . $in_keys->{$k}{'name'} . '\', ci_value => $args{\'' . $in_keys->{$k}{'name'} . '\'}});' . "\n\n";
      }
    };

    $stmt .= '  my $dbi = ' . $config->{'dbi_func'} . ';' . "\n"; 
    $stmt .= '  my $sth;' . "\n\n";

    # process input
    for ($dioh->{'cd_type'}) {
      /^DBI-Factory$/ && do {
        if ($in_keys) {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          my $extra = "";
          # check for limit or offset
          foreach my $k (@{ $in_keys }{ keys %{ $in_keys } }) {
            for ($k->{'name'}) {
              /^limit$/ && do { $extra .= ' limit \' . $args->{\'limit\'} . \''; last; };
              /^mysql_limit$/ && do { $extra .= ' limit \' . $args->{\'mysql_limit\'} . \''; last; };
              /^offset$/ && do { $extra .= ' offset \' . $args->{\'offset\'} . \''; last; };
            }
          }
          $stmt .= '    $sth = $dbi->db_prep(\'' . $dioh->{'cd_stmt'} . $extra . '\');' . "\n";
          $stmt .= '    $dbi->db_exec($sth, @$args{ ';
          my @c;
          foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
            push @c, '\'' . $k->{'name'} . '\'' if $k->{'name'} !~ /(mysql_limit|offset)/;
          }
          $stmt .= join(',', @c) . ' });' . "\n\n";
        } else {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  $sth = $dbi->db_sql(\'' . $dioh->{'cd_stmt'} . '\');' . "\n\n";
        }
        last;
      };
      /^DBI-Factory-Prep$/ && do {
        if ($in_keys) {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  $sth = $dbi->db_prep(\'' . $dioh->{'cd_stmt'} . '\');' . "\n\n";
        } else {
          $dioh->{'cd_stmt'} =~ s/'/\\'/g;
          $stmt .= '  $sth = $dbi->db_sql(\'' . $dioh->{'cd_stmt'} . '\');' . "\n\n";
        }
        last;
      };
    }

    # begin factory function
    $stmt .= '  return sub {' . "\n";

    # setup return type
    for ($dioh->{'cd_return'}) {
      /^none$/ && $dioh->{'cd_type'} && do {
        $stmt .= '    my ($args) = @_;' . "\n";
        $stmt .= '    if ($args) {' . "\n";
        $stmt .= '      $dbi->db_exec($sth, @$args{ ';
        my @c;
        foreach my $k (@{ $in_keys }{ sort {$a <=> $b} keys %{ $in_keys } }) {
          push @c, '\'' . $k->{'name'} . '\'';
        }
        $stmt .= join(',', @c) . ' });' . "\n";
        $stmt .= '    } else {' . "\n";
        $stmt .= '      $dbi->db_done($sth);' . "\n";
        $stmt .= '    }' . "\n";
        last;
      };
      /^scalar$/ && do {
        $stmt .= '    my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '    if (@d) {' . "\n";
        $stmt .= '      return @d;' . "\n";
        $stmt .= '    } else {' . "\n";
        $stmt .= '      $dbi->db_done($sth);' . "\n";
        $stmt .= '      return;' . "\n";
        $stmt .= '    }' . "\n";
        last;
      };
      /^array$/ && do {
        $stmt .= '    my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '    if (@d) {' . "\n";
        $stmt .= '      return \@d;' . "\n";
        $stmt .= '    } else {' . "\n";
        $stmt .= '      $dbi->db_done($sth);' . "\n";
        $stmt .= '      return;' . "\n";
        $stmt .= '    }' . "\n";
        last;
      };
      /^hash$/ && do {
        $stmt .= '    my $out_h;' . "\n";
        $stmt .= '    my @d = $dbi->db_fetch($sth);' . "\n";
        $stmt .= '    if (@d) {' . "\n";
        my $kc =  scalar keys %{ $out_keys };
        $stmt .= '      @$out_h{ \'' . join('\',\'',keys %{ $out_keys }) . '\' } = ' . q{map {((defined $_)?$_:'')} } . ($kc > 1 ?'@':'$') . 'd[ ';
        my @c;
        foreach my $k (@{ $out_keys }{ keys %{ $out_keys } }) { push @c, $k->{'pos'};}
        $stmt .= join(',',@c) . '];' . "\n";
          $stmt .= $pstmt if $profile;
        $stmt .= '      return $out_h;' . "\n";
        $stmt .= '    } else {' . "\n";
        $stmt .= '      $dbi->db_done($sth);' . "\n";
        $stmt .= '      return;' . "\n";
        $stmt .= '    }' . "\n";
        last;
      };
    }
    $stmt .= '  };' . "\n";
    $stmt .= '}' . "\n";

    if ($file_name) {
      print OUT_FILE $stmt;
    } else {
      eval "$stmt";
      #warn $@ if $@ && $debug;
      warn $@ if $@;
    }
    print "$stmt\n" if $verbose;
  }
  }

  $file_name && do {
    print OUT_FILE "\n1;\n";
    close OUT_FILE;
    rename $file_name .'t', $file_name;
  };
}
1;
