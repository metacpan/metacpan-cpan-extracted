package App::Test::Generator::LCSAJ;
use strict;
use warnings;
use PPI;
use JSON::MaybeXS;
use File::Spec;
use File::Path qw(make_path);
use Carp;

=head1 NAME

App::Test::Generator::LCSAJ - Static LCSAJ extraction for Perl

=head1 SYNOPSIS
  use App::Test::Generator::LCSAJ;
  App::Test::Generator::LCSAJ->generate('lib/MyModule.pm');

=head1 DESCRIPTION

Extracts linear code sequences and jump targets from Perl files.
=cut

sub generate {
    my ($class, $file, $out_dir) = @_;
    $out_dir //= 'lcsaj';

    my $doc = PPI::Document->new($file)
      or croak "Cannot parse $file";

    my $subs = $doc->find('PPI::Statement::Sub') || [];
    my @all_paths;

    for my $sub (@$subs) {
        my $blocks = _build_cfg($sub);
        my $paths  = _cfg_to_lcsaj($blocks);
        push @all_paths, @$paths;

        # Save DOT
        my $dot = _cfg_to_dot($blocks);
        _save_dot($file, $out_dir, $dot);
    }

	_save_lcsaj($file, $out_dir, \@all_paths);
	return \@all_paths;
}

# --- CFG Building ---
sub _build_cfg {
    my ($sub) = @_;
    my $block = $sub->block or return [];
    my @statements = $block->schildren;
    my @blocks;
    my $id = 1;
    my $current = _new_block($id);

    for my $stmt (@statements) {
        my $line = $stmt->line_number;
        push @{ $current->{lines} }, $line;

        if (_is_branch($stmt)) {
            push @blocks, $current;
            my $true_block  = _new_block(++$id);
            my $false_block = _new_block(++$id);
            _connect_blocks($current, $true_block);
            _connect_blocks($current, $false_block);
            push @blocks, $true_block, $false_block;
            $current = $true_block;
        }
    }

    push @blocks, $current;

    # Connect fallthrough edges
    for (my $i=0;$i<$#blocks;$i++) {
        next if @{ $blocks[$i]{edges} };
        _connect_blocks($blocks[$i], $blocks[$i+1]);
    }

    return \@blocks;
}

sub _new_block { my ($id)=@_; {id=>$id, lines=>[], edges=>[]} }
sub _connect_blocks { my ($from,$to)=@_; push @{ $from->{edges} }, $to->{id} }
sub _is_branch { my $s=shift; return 0 unless $s->isa('PPI::Statement::Compound'); my $t=$s->type||''; return 1 if $t=~/^(if|unless|while|for|foreach)$/; 0 }

# --- CFG → LCSAJ ---
sub _cfg_to_lcsaj {
    my $blocks = shift;
    my @paths;
    my %id2line = map { $_->{id} => $_->{lines}[0] } grep { @{ $_->{lines} } } @$blocks;

    for my $b (@$blocks) {
        next unless @{ $b->{edges} };
        my $start = $b->{lines}[0];
        my $end   = $b->{lines}[-1];
        for my $t (@{ $b->{edges} }) {
            push @paths, {start=>$start, end=>$end, target=>$id2line{$t}//0};
        }
    }
    \@paths;
}

# --- DOT ---
sub _cfg_to_dot {
    my $blocks = shift;
    my $dot="digraph cfg {\n";
    for my $b (@$blocks) {
        for my $e (@{ $b->{edges} }) { $dot.="  $b->{id} -> $e;\n" }
    }
    $dot.="}\n";
}

sub _save_lcsaj {
    my ($file,$dir,$paths)=@_;
    make_path($dir) unless -d $dir;
    my $out = File::Spec->catfile($dir, (split m{/}, $file)[-1] . '.lcsaj.json');
    open my $fh, '>', $out or die $!;
    print $fh encode_json($paths);
    close $fh;
}

sub _save_dot {
    my ($file,$dir,$dot)=@_;
    make_path($dir) unless -d $dir;
    my $out = File::Spec->catfile($dir, (split m{/}, $file)[-1] . '.lcsaj.dot');
    open my $fh, '>', $out or die $!;
    print $fh $dot;
    close $fh;
}

1;
