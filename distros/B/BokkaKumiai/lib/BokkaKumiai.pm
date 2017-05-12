package BokkaKumiai;
use Mouse;
use Mouse::Util::TypeConstraints;
our $VERSION = '0.02';

#- type
subtype 'BokkaKumiai::Keys'
	=> as 'Str',
	=> where { $_ =~ /^(C|C#|Db|D|D#|Eb|E|F|F#|Gb|G|G#|Ab|A|A#|Bb|B)$/ }
	=> message { "This key ($_) is not musical keys!" }
;
subtype 'BokkaKumiai::Time'
	=> as 'Str',
	=> where { $_ =~ /^\d+\/\d+$/ }
	=> message { "This time ($_) is not musical time!" }
;
subtype 'BokkaKumiai::Beat'
	=> as 'Int',
	=> where { $_ =~ /^(2|4|8|16)$/ },
	=> message { "This beat ($_) is not musical beat!" }
;
subtype 'BokkaKumiai::Tension'
	=> as 'Int',
	=> where { $_ =~ /^(undef|0|1|2|3|4)$/ }
	=> message { "This tention level ($_) is not supperted by BokkaKumiai.enter 1-4" }
;
subtype 'BokkaKumiai::OneRow'
	=> as 'Int',
	=> where { $_ =~ /^(2|4)$/ }
	=> message { "This bars_by_one_row  ($_) is not supperted by BokkaKumiai: enter 2 or 4" }
;

#- input 
has 'key' => (
	is => 'rw',
	isa => 'BokkaKumiai::Keys',
	required => 1,
);
has 'time' => (
	is => 'rw',
	isa => 'BokkaKumiai::Time',
	required => 1,
	default => '4/4',
);

has 'beat' => (	
	is => 'rw',
	isa => 'BokkaKumiai::Beat',
	default => 4,
	required => 1,
);
has 'pattern' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has 'chord_progress' => (	#- コード進行
	is => 'rw',
	isa => 'ArrayRef',
);

has 'tension' => (
	is => 'rw',
	isa => 'BokkaKumiai::Tension',
);

has 'bars_by_one_row' => (	#- 一行の小節数（タブ）
	is => 'rw',
	isa => 'BokkaKumiai::OneRow',
	default => 2,
);
__PACKAGE__->meta->make_immutable;
no Mouse;
no Mouse::Util::TypeConstraints;

use Data::Dumper;

#- customize your favorite chords
#- if undefined, substituted by auto calculated chords.
my $guitar_chords = +{
	'standard' => +{
		'C' => [qw(0 1 0 2 3 X)],
		'Cm' =>[qw(3 4 5 5 3 3)],
		'C6'=> [qw(0 1 2 2 3 X)],
		'C69'=>[qw(0 3 2 2 3 X)],
		'CM7'=>[qw(0 0 0 2 3 X)],
		'C7' =>[qw(0 1 3 2 3 X)],
		'C#' =>[qw(4 6 6 6 4 4)],
		'C#M7'=>[qw(4 6 5 6 4 4)],
		'D' => [qw(2 3 2 0 0 X)],
		'D7'=> [qw(2 1 2 0 0 X)],
		'Dm'=> [qw(1 3 2 0 0 X)],
		'Dm7'=>[qw(1 1 2 0 0 X)],
		'Eb'=> [qw(6 8 8 8 6 6)],
		'Eb7'=>[qw(6 8 6 8 6 6)],
		'E'=>  [qw(0 0 1 2 2 0)],
		'E7'=> [qw(0 0 1 0 2 0)],
		'Em'=> [qw(0 0 0 2 2 0)],
		'Em7'=>[qw(0 0 0 0 2 0)],
		'F' => [qw(1 1 2 3 3 1)],
		'Fm'=> [qw(1 1 1 3 3 1)],
		'FM7'=>[qw(0 1 2 3 3 X)],
		'FM79'=>[qw(0 1 0 3 3 X)],
		'G' => [qw(3 0 0 0 2 3)],
		'Gm'=> [qw(3 3 3 5 5 3)],
		'G7'=> [qw(1 0 0 0 2 3)],
		'Ab'=> [qw(4 4 5 6 6 4)],
		'Ab6'=>[qw(X 6 5 6 6 X)],
		'Ab7'=>[qw(4 4 5 4 6 4)],
		'Am'=> [qw(0 1 2 2 0 0)],
		'Am7'=>[qw(0 1 0 2 0 0)],
		'Bb'=> [qw(1 3 3 3 1 1)],
		'Bbm'=>[qw(1 2 3 3 1 1)],
		'Bb7'=>[qw(1 3 1 3 1 1)],
		'Bbm7'=>[qw(1 2 1 3 1 1)],
		'B'=>  [qw(2 4 4 4 2 2)],
		'Bm'=> [qw(2 3 4 4 2 2)],
	},
	'funky' => +{
		#- now developing..
	},
};

#- サブルーチン群
#- コード進行出力
sub print_chord_progress {
	my ( $self ) = shift;
	my ( $output ) = "Time: $self->{time}\n";
	$output .= "Beat: $self->{beat}\n";
	$output .= "Key : $self->{key}\n";
	my ( $cntr ) = 0;
	foreach my $bar ( @{$self->{chord_progress}} ){
		$output .= sprintf("| %-8s", $bar);
		$cntr++;
		if ( $cntr % 4 eq 0 ) {
			$output .= "|\n";
		}
	}
	print $output . "\n";
}
#- 拍とビートのチェック（制約）
sub check_time_and_beat {
	my ( $self, $beat, $time ) = @_;
	if ( ( $beat >= 8 ) &&  ( $time ne '8/8' ) ) {
		print "Error: 8 or 16 beat must be used in 8/8 time music.\n";
		exit;	
	}
}

#- コード進行をパターンから生成
sub mk_chord_progress {
	my $self = shift;
	$self->check_time_and_beat($self->{beat}, $self->{time});;
	my $cp;	#- array ref
	if ( $self->{pattern} eq 'pachelbel' ) {
		$self->{chord_progress} = ['I V/VII', 'VIm IIIm/V', 'IV I/III', 'IV/II V7'];
	} elsif ( $self->{pattern} eq 'blues' ) {
		$self->{chord_progress} = ['I', 'I', 'I', 'I', 'IV', 'IV', 'I', 'I', 'V', 'IV', 'I', 'V7'];
	} elsif ( $self->{pattern} eq 'vamp' ) {
		$self->{chord_progress} = ['I', 'I', 'IV', 'IV', 'I', 'I', 'IV', 'IV'];
	} elsif ( $self->{pattern} eq 'icecream' ) {
		$self->{chord_progress} = ['I', 'VIm', 'IIm', 'V7', 'I', 'VIm', 'IIm', 'V7'];
	} elsif ( $self->{pattern} eq 'major3' ) {
		$self->{chord_progress} = ['bVI', 'bVII', 'I', 'I'];
	} elsif ( $self->{pattern} eq 'iwantyouback' ) {
		$self->{chord_progress} = ['I','IV','VIm I/III IVM7 I','IIm7 V7 I I'];
	}
	if ( $self->{tension} )  {
		$self->add_tension;
	}
	$self->adjust_keys;
}

#- キーに合わせる
sub adjust_keys {
	my ( $self ) = shift;
	my ( $wholetone ) = 	['C','C#', 'D',  'Eb',  'E', 'F', 'F#','G', 'Ab', 'A',  'Bb',  'B'];
	my ( $relative_tone ) = {
		'I' => 0,
		'#I' => 1,
		'II' => 2,
		'bIII' => 3,
		'III' => 4,
		'IV' => 5,
		'#IV'=>6,
		'V' => 7,
		'bVI'=>8,
		'VI'=>9,
		'bVII' => 10,
		'VII' => 11
	};
	$wholetone = $self->arrange_order( $wholetone );
	my ( $many_chords ) = 0;
	my ( $pedal_chords ) = 0;
	foreach my $bar ( @{$self->{chord_progress}} ) {
		my @chords;
		if ( $bar =~ /\s+/ ) {
			@chords = split (/\s+/, $bar);
			$many_chords = 1;
		} else {
			push @chords, $bar;
		}
		foreach my $chord ( @chords ) {
			my ( @notes );
			if ( $chord =~ /\// ) {
				@notes = split (/\//, $chord );
				$pedal_chords = 1;
			} else {
				push @notes, $chord;
			}
			foreach my $note ( @notes ) {	#- 1コードレベル
				my ( $minor_Major );
				if ( $note =~ /([mM\d]+)$/ ) {
					$minor_Major = $1;
					$note =~ s/$minor_Major//;
				}
				my ( $pntr ) = $relative_tone->{$note};
				if ( $minor_Major ) {
					$note = $wholetone->[$pntr] . $minor_Major;
				} else { 
					$note = $wholetone->[$pntr];
				}
			}
			if ( $pedal_chords ) {
				$chord = join ('/', @notes);
			} else {
				$chord = $notes[0];
			}
		}
		if ( $many_chords ) {
			$bar = join (' ', @chords);
		} else {
			$bar = $chords[0];
		}
	}

}

#- ホールトーンスケールの順序を変える
sub arrange_order {
	my ( $self, $wholetone ) = @_;
	my ( $neworder ) = [];
	my ( @tmparray_before, @tmparray );
	my ( $done ) = 0;
	for ( my $i = 0; $i <= $#$wholetone; $i++ ) {
		if ( $self->{key} eq $wholetone->[$i] ) {
			$done = 1;
			push @tmparray, $wholetone->[$i];
		} elsif ( $done < 1 )  {
			push @tmparray_before, $wholetone->[$i];
		} else {
			push @tmparray, $wholetone->[$i];
		}
	}
	push @tmparray, @tmparray_before;
	$neworder = \@tmparray;
	return $neworder;
}

#- テンションをつける
sub add_tension {
	my ( $self ) = shift;
	my ( $tension_notes ) = {
		#- 適当
		'I' => ['6', '69', 'M7', 'M79'],
		'#I' => [],
		'II' => ['7'],
		'bIII' => ['7'],
		'III' => ['7'],
		'IV' => ['M7', 'M79', 'M713'],
		'#IV'=> [],
		'V' => ['7', '79', '713'],
		'bVI'=>['7'],
		'VI'=>['7'],
		'bVII' => ['7'],
		'VII' => [], 
	};
	my ( $many_chords ) = 0;
	my ( $pedal_chords ) = 0;
	foreach my $bar ( @{$self->{chord_progress}} ) {
		my @chords;
		if ( $bar =~ /\s+/ ) {
			@chords = split (/\s+/, $bar);
			$many_chords = 1;
		} else {
			push @chords, $bar;
		}
		foreach my $chord ( @chords ) {
			my $pedal_chord;
			if ( $chord =~ '/' ) {
				( $chord, $pedal_chord) = split ('/', $chord);
			}
			$chord =~ s/\d+$//g;
			my ( $minor_Major );
			if ( $chord =~ /([mM])$/ ) {
				$minor_Major = $1;
				$chord =~ s/$minor_Major//;
			}	
			#- def tension
			my $tension = '';
			for ( my $i = ($self->{tension} - 1); $i >= 0; $i-- ) {
				if ( $tension_notes->{$chord}->[$i] ) {
					$tension = $tension_notes->{$chord}->[$i];
					last;
				}
			}
			if ( $minor_Major ) {
				$chord .= $minor_Major . $tension;
			} else { 
				$chord .= $tension;
			}
			# bug patch :-)
			$chord =~ s/MM/M/;
			$chord =~ s/mm/m/;

			if ( $pedal_chord ) {
				$chord .= '/' . $pedal_chord;
			}
		}
		if ( $many_chords ) {
			$bar = join (' ', @chords);
		} else {
			$bar = $chords[0];
		}
	}
}

#- ギタータブ譜を書く
sub guitar_tab {
	my $self = shift;
	my $one_bar_str = 1;
	my $guitar_str = [qw(e B G D A E)];
	my $tab = +{};
	my $print_out_block = +{};	#-書き出し用単位
	my $beat_tick = +{};
	my $tab_blocks = 0;
	#- 拍子で長さを決める。フォーマトbuild_tab_format;
	my ( $child, $mother, $one_bar_length, $one_beat_length, $one_row, $one_bar_tick ) = $self->build_tab_format;
	my $bar_cnt = 0;
	my $bars_by_one_row = $self->{bars_by_one_row};
	#- コード進行に応じた一小節ごとのループ
	for my $bar ( @{$self->{chord_progress}} ) {
		#- 一行目のコード進行表示部分
		if ( $bar_cnt % $bars_by_one_row == 0 ) {
			$print_out_block->{$tab_blocks} .= '   ';
		} else {
			$print_out_block->{$tab_blocks} .= '  ';
		}
		my ( @chords );
		if ( $bar =~ / / ) {
			@chords = split (/ /, $bar);
		} else {
			push @chords, $bar;
		}
		my ( $chords_in_one_bar ) = $#chords + 1; #-一小節内のコード数
		my ( $bytes_for_one_chord ) = int( $one_bar_length / $chords_in_one_bar ); #- 3つあるときは？？ #-ひとつのコードごとに持つ拍数
		my ( $chord_num ) = 0;
		for my $chord ( @chords ) {
			my $format = '%-' . $bytes_for_one_chord . 's';
			$print_out_block->{$tab_blocks} .= sprintf($format, $chord);
		}
		if ( $bar_cnt % $bars_by_one_row == ($bars_by_one_row -1) ) {
			$print_out_block->{$tab_blocks} .= "\n";
		}
		#- 以上ヘッダづくり
		my $string_num = 0;
		#- ギターの弦ごとのループ
		for my $string ( @{$guitar_str} ) {
			my $one_tab_row = $one_row;
			#- コードの内容に応じて、指をおく。
			my ( $chord_num ) = 0;
			for my $chord ( @chords ) {
				my ( $chords_in_one_bar ) = $#chords + 1; #-一小節内のコード数
				my ( $bytes_for_one_chord ) = int( $one_bar_length / $chords_in_one_bar ); #-ひとつのコードごとに持つ拍数
				if ( $chord  =~ /(\/[A-Z#b]+)/ ) {
					$chord =~ s/$1//g;
				}
				if ( ( defined $guitar_chords->{standard}->{$chord}->[$string_num] ) &&  ( $guitar_chords->{standard}->{$chord}->[$string_num] ne '' )) {
					#- コードが明示されていない場合、相対的に決めるルーチンも欲しい。
					my $string_len = length ( $guitar_chords->{standard}->{$chord}->[$string_num] );
					#- 置き換え位置をここで決めている。
					#- 強拍は一応押さえる。
					for ( my $j = 0; $j < $bytes_for_one_chord; $j++ ) {
						if ( ( $self->{beat} == 2 ) or ( $self->{beat} == 4) ) {
							#- 拍の頭なら
							if ( $j % $one_beat_length == 0 ) {
								my $offset = $self->return_offset($self->{beat}, $bytes_for_one_chord, $chord_num, $j);
								#- 弦を押さえる。
								substr($one_tab_row, $offset, $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
							}
						} elsif ( $self->{beat} == 8 )  {
							#- 強拍
							if ( ( $bytes_for_one_chord >= ( $one_beat_length * 4 ) ) && ( $j % ( $one_beat_length * 4 )  == 0 ))  {
								#- 1コードが2分音符以上続く場合
								my $offset = $self->return_offset($self->{beat}, $bytes_for_one_chord, $chord_num, $j);
								#- 強拍
								substr($one_tab_row, $offset, $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								substr($one_tab_row, ($offset + 16) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								#- 弱拍の考慮 mute beat
								substr($one_tab_row, ($offset + 12),  $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								substr($one_tab_row, ($offset + 28),  $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
							} elsif ( ( $bytes_for_one_chord = $one_beat_length ) && ( $j % $one_beat_length == 0 ))  {
								#- 1コード一つの四分音符の場合
								my $offset = $self->return_offset($self->{beat}, $bytes_for_one_chord, $chord_num, $j);
								substr($one_tab_row, $offset, $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								#- 弱拍
								substr($one_tab_row, ($offset + 4), $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);

							}
						} elsif ( $self->{beat} == 16) {
							if ( $string_num >= 3 ) {
								#- 16ビートの場合、第四弦以下は弾かない。
								next;
							}
							#- 強拍
							if ( $j % ( $one_beat_length * 4 )  == 0 )  {
								#- あくまでもサンプルカッティング（センスよくしたいw
								my $offset = $self->return_offset($self->{beat}, $bytes_for_one_chord, $chord_num, $j);
								substr($one_tab_row, $offset, $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								substr($one_tab_row, ( $offset + 2) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								substr($one_tab_row, ( $offset + 4) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
								if ( $bytes_for_one_chord >= ( $one_beat_length * 4 ) ) {
									substr($one_tab_row, ( $offset + 8 ) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
									substr($one_tab_row, ( $offset + 10 ) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);
									substr($one_tab_row, ( $offset + 14 ) , $string_len, $guitar_chords->{standard}->{$chord}->[$string_num]);

								} 
							}
						}
					}
				}
				$chord_num++;
			}

			if ( $bar_cnt % $bars_by_one_row == 0 ) {
				$tab->{$bar_cnt}->{$string} =  "$string:$one_tab_row|"; #- 譜面を書く
			} else {
				$tab->{$bar_cnt}->{$string} =  "$one_tab_row|";	#- 譜面を書く
			}
			#- 最後に来て、かつ2ブロック目ならまとめて書きだしハッシュを作る
			if (( $bar_cnt % $bars_by_one_row == ( $bars_by_one_row - 1)) && ( $#$guitar_str == $string_num )) {
				#- 一拍ごとの区切りをつける
				$print_out_block->{$tab_blocks} .= ' ';
				for ( my $i = 0; $i < $bars_by_one_row; $i++ ) {
					$print_out_block->{$tab_blocks} .= ' '. $one_bar_tick;
				}
				$print_out_block->{$tab_blocks} .= "\n";
				#- 各弦ごとのタブを連結
				for my $Str ( @{$guitar_str} ) {
					for my $i ( sort {$a<=>$b} keys %$tab ) {
						$print_out_block->{$tab_blocks} .= $tab->{$i}->{$Str};
					}
					$print_out_block->{$tab_blocks} .=  "\n";
				}
				$tab_blocks++;
				$tab = undef;
			}
			$string_num++;
		}
		$bar_cnt++;
	}
	#- 出力する
	for my $cnt ( sort {$a<=>$b} keys %$print_out_block ) {
		print $print_out_block->{$cnt};
	}
}

#-弦上のオフセット戻し
sub return_offset {
	my ( $self, $beat, $bytes_for_one_chord, $chord_num, $j) = @_;
	if ( $beat !~ /^\d+$/ ) {
		die "beat must be number: $beat";
	}
	if ( ( $beat == 2 ) || ( $beat == 4) || ( $beat == 16 )) {
		return ( 1 + ($bytes_for_one_chord  *  $chord_num  ) + $j );
	} elsif ( $beat == 8)  {
		return ( 1 + ($bytes_for_one_chord  *  $chord_num * 2 ) + $j );
	}


}

#- 一小節のフォーマットづくり
sub build_tab_format {
	my $self = shift;
	my ( $one_bar_length, $one_beat_length, $one_row, $one_bar_tick);
	my ( $child, $mother ) = split ('/', $self->{time} );
	if ( ( $mother == 4 ) || ( $mother == 2) )  {
		$one_bar_length =  $mother * $child ;
	} elsif ( ( $mother == 8 ) || ( $mother == 16 ) )  {
		$one_bar_length =  ( $mother * $child ) / 2 ;
	}
	$one_beat_length = $one_bar_length / $child;
	for ( my $i = 0; $i < $one_bar_length; $i++ ) {
		$one_row .= '-';
		if ( ( $self->{beat} =~ /^(2|4)$/ ) && ( $i % $one_beat_length == 0 ) )  {
			$one_bar_tick .= '+';
		} elsif ( ( $self->{beat} =~ /^(8|16)$/)  && ( $i %  8 == 0 ) )  {
			$one_bar_tick .= '+';
		} elsif ( ( $self->{beat} =~ /^(8|16)$/ ) && ( $i %  4 == 0 ) )  {
			$one_bar_tick .= '-';
		} else {
			$one_bar_tick .= ' ';
		}
	}
	$one_row .= '-';	#-見やすくするため一つ足す
	$one_bar_tick = ' ' . $one_bar_tick;
	return ( $child, $mother, $one_bar_length, $one_beat_length, $one_row, $one_bar_tick);
}

1;
__END__

=head1 NAME

BokkaKumiai - Music Chord Progression Analysis Module, with writing Guitar Tabs methods.


=head1 SYNOPSIS
    #Pachelbel's Canon's Guitar Tab in C.
    use BokkaKumiai;
    my $cp = BokkaKumiai->new(
        'key' => 'C',
        'time' => '4/4',
        'beat' => 4,
        'pattern' => 'pachelbel',  #- 'Pachelbel's Canon'
        'bars_by_one_row' => 2,
    );
    $cp->mk_chord_progress;
    $cp->print_chord_progress;
    $cp->guitar_tab;	



    #Jackson5 "I want You Back " Guitar Tab in Ab.
    use BokkaKumiai;
    my $cp = BokkaKumiai->new(
        'key' => 'Ab',
        'time' => '8/8',
        'beat' => 16, 
        'pattern' => 'iwantyouback',
        'tension' => 2,
        'bars_by_one_row' => 2,
    );
    $cp->mk_chord_progress;
    $cp->print_chord_progress;
    $cp->guitar_tab;	

=head1 DESCRIPTION

My dream is to make "Intelligent Music DataBase System", which has Chord Progression DB and analyze music making techniques easily to bring up new talents in the future.
BokkaKumiai is made to analyze Music Chord Progression.

Give BokkaKumiai, key(ex. C, Am.. ), time(4/4, 8/8, 3/4 etc..) and beat(4beat, 8beat, etc..),
and define chord progression pattern,
you will get guitar tab sample, automatically!!

This version is ALPHAAA version, I'm developing in now, so forgive some bugs and tell me please!!
 
=head1 AUTHOR

DUKKIE E<lt>dukkiedukkie@yahoo.co.jpE<gt>

thanks to Bokka Kumiai readers.
http://ameblo.jp/dukkiedukkie/

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, Musicians and JASRAC!

=cut
