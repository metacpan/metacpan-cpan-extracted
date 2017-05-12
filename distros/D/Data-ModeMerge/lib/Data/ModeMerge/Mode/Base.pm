package Data::ModeMerge::Mode::Base;

our $DATE = '2016-07-22'; # DATE
our $VERSION = '0.35'; # VERSION

use 5.010;
use strict;
use warnings;

#use Data::Dmp;

#use Log::Any '$log';
use Mo qw(build default);

#use Data::Clone qw/clone/;

has merger => (is => 'rw');
has prefix => (is => 'rw');
has prefix_re => (is => 'rw');
has check_prefix_sub => (is => 'rw');
has add_prefix_sub => (is => 'rw');
has remove_prefix_sub => (is => 'rw');

sub name {
    die "Subclass must provide name()";
}

sub precedence_level {
    die "Subclass must provide precedence_level()";
}

sub default_prefix {
    die "Subclass must provide default_prefix()";
}

sub default_prefix_re {
    die "Subclass must provide default_prefix_re()";
}

sub BUILD {
    my ($self) = @_;
    $self->prefix($self->default_prefix);
    $self->prefix_re($self->default_prefix_re);
}

sub check_prefix {
    my ($self, $hash_key) = @_;
    if ($self->check_prefix_sub) {
        $self->check_prefix_sub->($hash_key);
    } else {
        $hash_key =~ $self->prefix_re;
    }
}

sub add_prefix {
    my ($self, $hash_key) = @_;
    if ($self->add_prefix_sub) {
        $self->add_prefix_sub->($hash_key);
    } else {
        $self->prefix . $hash_key;
    }
}

sub remove_prefix {
    my ($self, $hash_key) = @_;
    if ($self->remove_prefix_sub) {
        $self->remove_prefix_sub->($hash_key);
    } else {
        my $re = $self->prefix_re;
        $hash_key =~ s/$re//;
        $hash_key;
    }
}

sub merge_ARRAY_ARRAY {
    my ($self, $key, $l, $r) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;
    return $self->merge_SCALAR_SCALAR($key, $l, $r) unless $c->recurse_array;
    return if $c->wanted_path && !$mm->_path_is_included($mm->path, $c->wanted_path);

    my @res;
    my @backup;
    my $la = @$l;
    my $lb = @$r;
    push @{ $mm->path }, -1;
    for my $i (0..($la > $lb ? $la : $lb)-1) {
        #print "DEBUG: merge_A_A: #$i: a->[$i]=".Data::Dumper->new([$l->[$i]])->Indent(0)->Terse(1)->Dump.", b->[$i]=".Data::Dumper->new([$r->[$i]])->Indent(0)->Terse(1)->Dump."\n";
        $mm->path->[-1] = $i;
        if ($i < $la && $i < $lb) {
            push @backup, $l->[$i];
            my ($subnewkey, $subres, $subbackup, $is_circular) = $mm->_merge($i, $l->[$i], $r->[$i], $c->default_mode);
            last if @{ $mm->errors };
            if ($is_circular) {
                push @res, undef;
                #print "DEBUG: pushing todo to mem<".$mm->cur_mem_key.">\n";
                push @{ $mm->mem->{ $mm->cur_mem_key }{todo} }, sub {
                    my ($subnewkey, $subres, $subbackup) = @_;
                    #print "DEBUG: Entering todo subroutine (i=$i)\n";
                    $res[$i] = $subres;
                }
            } else {
                push @res, $subres;# if defined($newkey); = we allow DELETE on array?
            }
        } elsif ($i < $la) {
            push @res, $l->[$i];
        } else {
            push @res, $r->[$i];
        }
    }
    pop @{ $mm->path };
    ($key, \@res, \@backup);
}

sub _prefilter_hash {
    my ($self, $h, $desc, $sub) = @_;
    my $mm = $self->merger;

    if (ref($sub) ne 'CODE') {
        $mm->push_error("$desc failed: filter must be a coderef");
        return;
    }

    my $res = {};
    for (keys %$h) {
        my @r = $sub->($_, $h->{$_});
        while (my ($k, $v) = splice @r, 0, 2) {
            next unless defined $k;
            if (exists $res->{$k}) {
                $mm->push_error("$desc failed; key conflict: ".
                                "$_ -> $k, but key $k already exists");
                return;
            }
            $res->{$k} = $v;
        }
    }

    $res;
}

# turn {[prefix]key => val, ...} into { key => [MODE, val], ...}, push
# error if there's conflicting key
sub _gen_left {
    my ($self, $l, $mode, $esub, $ep, $ip, $epr, $ipr) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;

    #print "DEBUG: Entering _gen_left(".dmp($l).", $mode, ...)\n";

    if ($c->premerge_pair_filter) {
        $l = $self->_prefilter_hash($l, "premerge filter left hash",
                                    $c->premerge_pair_filter);
        return if @{ $mm->errors };
    }

    my $hl = {};
    if ($c->parse_prefix) {
        for (keys %$l) {
            my $do_parse = 1;
            $do_parse = 0 if $do_parse && $ep  &&  $mm->_in($_, $ep);
            $do_parse = 0 if $do_parse && $ip  && !$mm->_in($_, $ip);
            $do_parse = 0 if $do_parse && $epr &&  /$epr/;
            $do_parse = 0 if $do_parse && $ipr && !/$ipr/;

            if ($do_parse) {
                my $old = $_;
                my $m2;
                ($_, $m2) = $mm->remove_prefix($_);
                next if $esub && !$esub->($_);
                if ($old ne $_ && exists($l->{$_})) {
                    $mm->push_error("Conflict when removing prefix on left-side ".
                                    "hash key: $old -> $_ but $_ already exists");
                    return;
                }
                $hl->{$_} = [$m2, $l->{$old}];
            } else {
                next if $esub && !$esub->($_);
                $hl->{$_} = [$mode, $l->{$_}];
            }
        }
    } else {
        for (keys %$l) {
            next if $esub && !$esub->($_);
            $hl->{$_} = [$mode, $l->{$_}];
        }
    }

    #print "DEBUG: Leaving _gen_left, result = ".dmp($hl)."\n";
    $hl;
}

# turn {[prefix]key => val, ...} into { key => {MODE=>val, ...}, ...},
# push error if there's conflicting key+MODE
sub _gen_right {
    my ($self, $r, $mode, $esub, $ep, $ip, $epr, $ipr) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;

    #print "DEBUG: Entering _gen_right(".dmp($r).", $mode, ...)\n";

    if ($c->premerge_pair_filter) {
        $r = $self->_prefilter_hash($r, "premerge filter right hash",
                                    $c->premerge_pair_filter);
        return if @{ $mm->errors };
    }

    my $hr = {};
    if ($c->parse_prefix) {
        for (keys %$r) {
            my $do_parse = 1;
            $do_parse = 0 if $do_parse && $ep  &&  $mm->_in($_, $ep);
            $do_parse = 0 if $do_parse && $ip  && !$mm->_in($_, $ip);
            $do_parse = 0 if $do_parse && $epr &&  /$epr/;
            $do_parse = 0 if $do_parse && $ipr && !/$ipr/;

            if ($do_parse) {
                my $old = $_;
                my $m2;
                ($_, $m2) = $mm->remove_prefix($_);
                next if $esub && !$esub->($_);
                if (exists $hr->{$_}{$m2}) {
                    $mm->push_error("Conflict when removing prefix on right-side ".
                                    "hash key: $old($m2) -> $_ ($m2) but $_ ($m2) ".
                                    "already exists");
                    return;
                }
                $hr->{$_}{$m2} = $r->{$old};
            } else {
                next if $esub && !$esub->($_);
                $hr->{$_} = {$mode => $r->{$_}};
            }
        }
    } else {
        for (keys %$r) {
            next if $esub && !$esub->($_);
            $hr->{$_} = {$mode => $r->{$_}}
        }
    }
    #print "DEBUG: Leaving _gen_right, result = ".dmp($hr)."\n";
    $hr;
}

# merge two hashes which have been prepared by _gen_left and
# _gen_right, will result in { key => [final_mode, val], ... }
sub _merge_gen {
    my ($self, $hl, $hr, $mode, $em, $im, $emr, $imr) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;

    #print "DEBUG: Entering _merge_gen(".dmp($hl).", ".dmp($hr).", $mode, ...)\n";

    my $res = {};
    my $backup = {};

    my %k = map {$_=>1} keys(%$hl), keys(%$hr);
    push @{ $mm->path }, "";
  K:
    for my $k (keys %k) {
        my @o;
        $mm->path->[-1] = $k;
        my $do_merge = 1;
        $do_merge = 0 if $do_merge && $em  &&  $mm->_in($k, $em);
        $do_merge = 0 if $do_merge && $im  && !$mm->_in($k, $im);
        $do_merge = 0 if $do_merge && $emr && $k =~ /$emr/;
        $do_merge = 0 if $do_merge && $imr && $k !~ /$imr/;

        if (!$do_merge) {
            $res->{$k} = $hl->{$k} if $hl->{$k};
            next K;
        }

        $backup->{$k} = $hl->{$k}[1] if $hl->{$k} && $hr->{$k};
        if ($hl->{$k}) {
            push @o, $hl->{$k};
        }
        if ($hr->{$k}) {
            my %m = map {$_=>$mm->modes->{$_}->precedence_level} keys %{ $hr->{$k} };
            #print "DEBUG: \\%m=".Data::Dumper->new([\%m])->Indent(0)->Terse(1)->Dump."\n";
            push @o, map { [$_, $hr->{$k}{$_}] } sort { $m{$b} <=> $m{$a} } keys %m;
        }
        my $final_mode;
        my $is_circular;
        my $v;
        #print "DEBUG: k=$k, o=".Data::Dumper->new([\@o])->Indent(0)->Terse(1)->Dump."\n";
        for my $i (0..$#o) {
            if ($i == 0) {
                my $mh = $mm->modes->{$o[$i][0]};
                if (@o == 1 &&
                        (($hl->{$k} && $mh->can("merge_left_only")) ||
                         ($hr->{$k} && $mh->can("merge_right_only")))) {
                    # there's only left-side or right-side
                    my $meth = $hl->{$k} ? "merge_left_only" : "merge_right_only";
                    my ($subnewkey, $v, $subbackup, $is_circular, $newmode) = $mh->$meth($k, $o[$i][1]); # XXX handle circular?
                    next K unless defined($subnewkey);
                    $final_mode = $newmode;
                    $v = $res;
                } else {
                    $final_mode = $o[$i][0];
                    $v = $o[$i][1];
                }
            } else {
                my $m = $mm->combine_rules->{"$final_mode+$o[$i][0]"}
                    or do {
                        $mm->push_error("Can't merge $final_mode + $o[$i][0]");
                        return;
                    };
                #print "DEBUG: merge $final_mode+$o[$i][0] = $m->[0], $m->[1]\n";
                my ($subnewkey, $subbackup);
                ($subnewkey, $v, $subbackup, $is_circular) = $mm->_merge($k, $v, $o[$i][1], $m->[0]);
                return if @{ $mm->errors };
                if ($is_circular) {
                    if ($i < $#o) {
                        $mm->push_error("Can't handle circular at $i of $#o merges (mode $m->[0]): not the last merge");
                        return;
                    }
                    #print "DEBUG: pushing todo to mem<".$mm->cur_mem_key.">\n";
                    push @{ $mm->mem->{ $mm->cur_mem_key }{todo} }, sub {
                        my ($subnewkey, $subres, $subbackup) = @_;
                        #print "DEBUG: Entering todo subroutine (k=$k)\n";
                        my $final_mode = $m->[1];
                        #XXX return unless defined($subnewkey);
                        $res->{$k} = [$m->[1], $subres];
                        if ($c->readd_prefix) {
                            # XXX if there is a conflict error in
                            # _readd_prefix, how to adjust path?
                            $self->_readd_prefix($res, $k, $c->default_mode);
                        } else {
                            $res->{$k} = $res->{$k}[1];
                        }
                    };
                    delete $res->{$k};
                }
                next K unless defined $subnewkey;
                $final_mode = $m->[1];
            }
        }
        $res->{$k} = [$final_mode, $v] unless $is_circular;
    }
    pop @{ $mm->path };
    #print "DEBUG: Leaving _merge_gen, res = ".dmp($res)."\n";
    ($res, $backup);
}

# hh is {key=>[MODE, val], ...} which is the format returned by _merge_gen
sub _readd_prefix {
    my ($self, $hh, $k, $defmode) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;

    my $m = $hh->{$k}[0];
    if ($m eq $defmode) {
        $hh->{$k} = $hh->{$k}[1];
    } else {
        my $kp = $mm->modes->{$m}->add_prefix($k);
        if (exists $hh->{$kp}) {
            $mm->push_error("BUG: conflict when re-adding prefix after merge: $kp");
            return;
        }
        $hh->{$kp} = $hh->{$k}[1];
        delete $hh->{$k};
    }
}

sub merge_HASH_HASH {
    my ($self, $key, $l, $r, $mode) = @_;
    my $mm = $self->merger;
    my $c = $mm->config;
    $mode //= $c->default_mode;
    #print "DEBUG: entering merge_H_H(".dmp($l).", ".dmp($r).", $mode), config=($c)=",dmp($c),"\n";
    #$log->trace("using config($c)");

    return $self->merge_SCALAR_SCALAR($key, $l, $r) unless $c->recurse_hash;
    return if $c->wanted_path && !$mm->_path_is_included($mm->path, $c->wanted_path);

    # STEP 1. MERGE LEFT & RIGHT OPTIONS KEY
    my $config_replaced;
    my $orig_c = $c;
    my $ok = $c->options_key;
    {
        last unless defined $ok;

        my $okl = $self->_gen_left ($l, $mode, sub {$_[0] eq $ok});
        return if @{ $mm->errors };

        my $okr = $self->_gen_right($r, $mode, sub {$_[0] eq $ok});
        return if @{ $mm->errors };

        push @{ $mm->path }, $ok;
        my ($res, $backup);
        {
            local $c->{readd_prefix} = 0;
            ($res, $backup) = $self->_merge_gen($okl, $okr, $mode);
        }
        pop @{ $mm->path };
        return if @{ $mm->errors };

        #print "DEBUG: merge options key (".dmp($okl).", ".dmp($okr).") = ".dmp($res)."\n";

        $res = $res->{$ok} ? $res->{$ok}[1] : undef;
        if (defined($res) && ref($res) ne 'HASH') {
            $mm->push_error("Invalid options key after merge: value must be hash");
            return;
        }
        last unless keys %$res;
        #$log->tracef("cloning config ...");
        # Data::Clone by default does *not* deep-copy object
        #my $c2 = clone($c);
        my $c2 = bless({ %$c }, ref($c));

        for (keys %$res) {
            if ($c->allow_override) {
                my $re = $c->allow_override;
                if (!/$re/) {
                    $mm->push_error("Configuration in options key `$_` not allowed by allow_override $re");
                    return;
                }
            }
            if ($c->disallow_override) {
                my $re = $c->disallow_override;
                if (/$re/) {
                    $mm->push_error("Configuration in options key `$_` not allowed by disallow_override $re");
                    return;
                }
            }
            if ($mm->_in($_, $c->_config_config)) {
                $mm->push_error("Configuration not allowed in options key: $_");
                return;
            }
            if ($_ ne $ok && !$mm->_in($_, $c->_config_ok)) {
                $mm->push_error("Unknown configuration in options key: $_");
                return;
            }
            $c2->$_($res->{$_}) unless $_ eq $ok;
        }
        $mm->config($c2);
        $config_replaced++;
        $c = $c2;
        #$log->trace("config now changed to $c2");
    }

    my $sp = $c->set_prefix;
    my $saved_prefixes;
    if (defined($sp)) {
        if (ref($sp) ne 'HASH') {
            $mm->push_error("Invalid config value `set_prefix`: must be a hash");
            return;
        }
        $saved_prefixes = {};
        for my $mh (values %{ $mm->modes }) {
            my $n = $mh->name;
            if ($sp->{$n}) {
                $saved_prefixes->{$n} = {
                    prefix => $mh->prefix,
                    prefix_re => $mh->prefix_re,
                    check_prefix_sub => $mh->check_prefix_sub,
                    add_prefix_sub => $mh->add_prefix_sub,
                    remove_prefix_sub => $mh->remove_prefix_sub,
                };
                $mh->prefix($sp->{$n});
                my $re = quotemeta($sp->{$n});
                $mh->prefix_re(qr/^$re/);
                $mh->check_prefix_sub(undef);
                $mh->add_prefix_sub(undef);
                $mh->remove_prefix_sub(undef);
            }
        }
    }

    my $ep = $c->exclude_parse;
    my $ip = $c->include_parse;
    if (defined($ep) && ref($ep) ne 'ARRAY') {
        $mm->push_error("Invalid config value `exclude_parse`: must be an array");
        return;
    }
    if (defined($ip) && ref($ip) ne 'ARRAY') {
        $mm->push_error("Invalid config value `include_parse`: must be an array");
        return;
    }

    my $epr = $c->exclude_parse_regex;
    my $ipr = $c->include_parse_regex;
    if (defined($epr)) {
        eval { $epr = qr/$epr/ };
        if ($@) {
            $mm->push_error("Invalid config value `exclude_parse_regex`: invalid regex: $@");
            return;
        }
    }
    if (defined($ipr)) {
        eval { $ipr = qr/$ipr/ };
        if ($@) {
            $mm->push_error("Invalid config value `include_parse_regex`: invalid regex: $@");
            return;
        }
    }

    # STEP 2. PREPARE LEFT HASH
    my $hl = $self->_gen_left ($l, $mode, sub {defined($ok) ? $_[0] ne $ok : 1}, $ep, $ip, $epr, $ipr);
    return if @{ $mm->errors };

    # STEP 3. PREPARE RIGHT HASH
    my $hr = $self->_gen_right($r, $mode, sub {defined($ok) ? $_[0] ne $ok : 1}, $ep, $ip, $epr, $ipr);
    return if @{ $mm->errors };

    #print "DEBUG: hl=".Data::Dumper->new([$hl])->Indent(0)->Terse(1)->Dump."\n";
    #print "DEBUG: hr=".Data::Dumper->new([$hr])->Indent(0)->Terse(1)->Dump."\n";

    my $em = $c->exclude_merge;
    my $im = $c->include_merge;
    if (defined($em) && ref($em) ne 'ARRAY') {
        $mm->push_error("Invalid config value `exclude_marge`: must be an array");
        return;
    }
    if (defined($im) && ref($im) ne 'ARRAY') {
        $mm->push_error("Invalid config value `include_merge`: must be an array");
        return;
    }

    my $emr = $c->exclude_merge_regex;
    my $imr = $c->include_merge_regex;
    if (defined($emr)) {
        eval { $emr = qr/$emr/ };
        if ($@) {
            $mm->push_error("Invalid config value `exclude_merge_regex`: invalid regex: $@");
            return;
        }
    }
    if (defined($imr)) {
        eval { $imr = qr/$imr/ };
        if ($@) {
            $mm->push_error("Invalid config value `include_merge_regex`: invalid regex: $@");
            return;
        }
    }

    # STEP 4. MERGE LEFT & RIGHT
    my ($res, $backup) = $self->_merge_gen($hl, $hr, $mode, $em, $im, $emr, $imr);
    return if @{ $mm->errors };

    #print "DEBUG: intermediate res(5) = ".Data::Dumper->new([$res])->Indent(0)->Terse(1)->Dump."\n";

    # STEP 5. TURN BACK {key=>[MODE=>val]}, ...} INTO {(prefix)key => val, ...}
    if ($c->readd_prefix) {
        for my $k (keys %$res) {
            $self->_readd_prefix($res, $k, $c->default_mode);
        }
    } else {
        $res->{$_} = $res->{$_}[1] for keys %$res;
    }

    if ($saved_prefixes) {
        for (keys %$saved_prefixes) {
            my $mh = $mm->modes->{$_};
            my $s = $saved_prefixes->{$_};
            $mh->prefix($s->{prefix});
            $mh->prefix_re($s->{prefix_re});
            $mh->check_prefix_sub($s->{check_prefix_sub});
            $mh->add_prefix_sub($s->{add_prefix_sub});
            $mh->remove_prefix_sub($s->{remove_prefix_sub});
        }
    }

    # restore config
    if ($config_replaced) {
        $mm->config($orig_c);
        #print "DEBUG: Restored config, config=", dmp($mm->config), "\n";
    }

    #print "DEBUG: backup = ".Data::Dumper->new([$backup])->Indent(0)->Terse(1)->Dump."\n";
    #print "DEBUG: leaving merge_H_H, result = ".dmp($res)."\n";
    ($key, $res, $backup);
}

1;
# ABSTRACT: Base class for Data::ModeMerge mode handler

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::ModeMerge::Mode::Base - Base class for Data::ModeMerge mode handler

=head1 VERSION

This document describes version 0.35 of Data::ModeMerge::Mode::Base (from Perl distribution Data-ModeMerge), released on 2016-07-22.

=head1 SYNOPSIS

 use Data::ModeMerge;

=head1 DESCRIPTION

This is the base class for mode type handlers.

=for Pod::Coverage ^(BUILD|merge_.+)$

=head1 ATTRIBUTES

=head2 merger

=head2 prefix

=head2 prefix_re

=head2 check_prefix_sub

=head2 add_prefix_sub

=head2 remove_prefix_sub

=head1 METHODS

=head2 name

Return name of mode. Subclass must override this method.

=head2 precedence_level

Return precedence level, which is a number. The greater the number,
the higher the precedence. Subclass must override this method.

=head2 default_prefix

Return default prefix. Subclass must override this method.

=head2 default_prefix_re

Return default prefix regex. Subclass must override this method.

=head2 check_prefix($hash_key)

Return true if hash key has prefix for this mode.

=head2 add_prefix($hash_key)

Return hash key with added prefix of this mode.

=head2 remove_prefix($hash_key)

Return hash key with prefix of this mode prefix removed.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-ModeMerge>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-ModeMerge>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-ModeMerge>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
