
use Test::Most;

use Fcntl;
use Time::HiRes;
use Digest::MD5;
use Data::Dumper;

use_ok('DataCube');
use_ok('DataCube::Cube');
use_ok('DataCube::Cube::Style');
use_ok('DataCube::Cube::Style::HTML');
use_ok('DataCube::Cube::Style::HTML::CSS');
use_ok('DataCube::Schema');
use_ok('DataCube::FileSplitter');
use_ok('DataCube::Report::Formatter');
use_ok('DataCube::FileUtils::CubeMerger');
use_ok('DataCube::FileUtils::FileReader');
use_ok('DataCube::FileUtils::FileMerger');
use_ok('DataCube::FileUtils::TableMerger');
use_ok('DataCube::Connection');
use_ok('DataCube::Connection::Table');


unroll_up:
{
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    $schema->add_hierarchy('year','quarter','month','day');
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    my $cube = DataCube->new($schema);
    my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
    $cube->load_data_infile( $file );
    my $cube2 = $cube->clone;
    $cube->rollup;
    $cube->unroll;
    is_deeply($cube,$cube2,'unroll_me');
}

ok(tb(),'table_ops');
ok(lr(),'lazy_list');
ok(ur(),'unroll_up');
ok(lg(),'log_files');
ok(mm(),'mini_max');
ok(vg(),'game_data');
ok(rd(),'rand_data');
ok(df(),'disk_file');
ok(pp(),'poss_pars');
ok(tc(),'test_crep');
ok(th(),'test_chtm');

done_testing;

sub tb {
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    $schema->add_hierarchy('year','quarter','month','day');
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    my $cube = DataCube->new( $schema );
    my $reader = DataCube::FileUtils::FileReader->new;
    my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
    my @records = $reader->slurp($file);
    for(@records){
        my $data = $_;
        for(keys %$data){
            next if /^(?:price|dollar|units)/i;
            $data->{$_} = '' if rand() < 0.5;
        }
    }
    
    {
        
        local $SIG{__WARN__} = sub {
            return 0;
        };
        
        $cube->insert($_) for @records;
        
        while(my $table = $cube->lazy_rollup){
            
            my @table   = $table->to_table;
            my $columns = $table->schema->field_count + $table->schema->measure_count;
            
            for(@table){
                return 0 unless @$_ == $columns;
            }
        
        }
        
        $cube->rollup;
        
        my $tables = $cube->tables;
        
        for(keys %$tables) {
            my $table = $tables->{$_};
            my $columns = $table->schema->field_count + $table->schema->measure_count;
            my @table = $table->to_table;
            for(@table) {
                return 0 unless @$_ == $columns;
            }
        }
        
        second_pass:{
            $cube->unroll;
            $cube->load_data_infile($file);
            while(my $table = $cube->lazy_rollup) {
                my @table   = $table->to_table;
                my $columns = $table->schema->field_count + $table->schema->measure_count;
                for(@table){
                    return 0 unless @$_ == $columns;
                }
            }      
            $cube->rollup;
            my $tables = $cube->tables;
            for(keys %$tables) {
                my $table = $tables->{$_};
                my $columns = $table->schema->field_count + $table->schema->measure_count;
                my @table = $table->to_table;
                for(@table) {
                    return 0 unless @$_ == $columns;
                }
            }
        }
    }
    return 1;
}



sub lr {
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_dimension('country');
        $schema->add_dimension('product');
        $schema->add_dimension('salesperson');
        $schema->add_hierarchy('year','quarter','month','day');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 40;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_strict_dimension('country');
        $schema->add_dimension('product');
        $schema->add_dimension('salesperson');
        $schema->add_hierarchy('year','quarter','month','day');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 20;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_strict_dimension('country');
        $schema->add_strict_dimension('product');
        $schema->add_dimension('salesperson');
        $schema->add_strict_hierarchy('year','quarter','month','day');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 8;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_strict_dimension('country');
        $schema->add_strict_dimension('product');
        $schema->add_strict_dimension('salesperson');
        $schema->add_strict_hierarchy('year','quarter','month','day');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 4;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_strict_dimension('country');
        $schema->add_strict_dimension('product');
        $schema->add_dimension('salesperson');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 2;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_strict_dimension('country');
        $schema->add_strict_dimension('product');
        $schema->add_strict_dimension('salesperson');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 1;
    }
    
    {
        my $schema = DataCube::Schema->new;
        $schema->add_dimension('country');
        $schema->add_dimension('product');
        $schema->add_dimension('salesperson');
        $schema->add_measure('sum','units_sold');
        $schema->add_measure('sum','dollar_volume');
        $schema->add_measure('average','price_per_unit');
        $schema->confine_to('country','salesperson');
        my $cube = DataCube->new($schema);
        my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
        $cube->load_data_infile( $file );
        my %count;
        while(my $table = $cube->lazy_rollup){
            $count{points}++;
        }
        return 0 unless $count{points} == 1;
    }
    
    return 1;
}


sub ur {
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    $schema->add_hierarchy('year','quarter','month','day');
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    my $cube = DataCube->new($schema);
    my $file = -f('sa') ? 'sa' : -f('t/sa') ? 't/sa' : die;
    $cube->load_data_infile( $file );
    my $cube2 = $cube->clone;
    $cube->rollup;
    $cube->unroll;
    return $cube->isa_copy_of($cube2);
}

sub mm {
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('x');
    $schema->add_dimension('y');
    $schema->add_measure('min','u');
    $schema->add_measure('max','v');
    my $cube = DataCube->new($schema);
    for(0..99) {
        $cube->insert({
            x => $_,
            y => $_,
            u => $_ + 1,
            v => $_ ** 2,
        });
    }
    $cube->rollup;
    
    my $x = $cube->cube_store->fetch('overall');
    return 0 unless $x->{cube}->{''}->{min}->{u} == 1;
    return 0 unless $x->{cube}->{''}->{max}->{v} == 9801;
    
    $x = $cube->cube_store->fetch('x');
    return 0 unless $x->{cube}->{33}->{min}->{u} == 34;
    return 0 unless $x->{cube}->{33}->{max}->{v} == 1089;
    
    $x = $cube->cube_store->fetch('y');
    return 0 unless $x->{cube}->{18}->{min}->{u} == 19;
    return 0 unless $x->{cube}->{18}->{max}->{v} == 324;
    
    $x = $cube->cube_store->fetch("x\ty");
    return 0 unless $x->{cube}->{"55\t55"}->{min}->{u} == 56;
    return 0 unless $x->{cube}->{"55\t55"}->{max}->{v} == 3025;
    
    return 1;
}

sub tc {
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    $schema->add_hierarchy('year','quarter','month','day');
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    my $cube = DataCube->new($schema);
    my @data = example_sales_data();
    
    for(my $i = 0; $i < @data; $i++){  
        my $date  = $data[$i][0];
        my($month,$day,$year) = split/\//,$date;
        my $quarter = $month > 0 && $month < 4  ? 'Q1' :
                      $month > 3 && $month < 7  ? 'Q2' :
                      $month > 6 && $month < 10 ? 'Q3' :
                      $month > 9 && $month < 13 ? 'Q4' : '';
        my %data = ();
        $data{year}           = $year;
        $data{quarter}        = $quarter;
        $data{month}          = sprintf("%02d",$month);
        $data{day}            = sprintf("%02d",$day);
        $data{country}        = $data[$i][1];
        $data{salesperson}    = $data[$i][2];
        $data{product}        = $data[$i][3];
        $data{units_sold}     = $data[$i][4];
        $data{price_per_unit} = $data[$i][5];
        $data{dollar_volume}  = $data[$i][6];
        $cube->insert(\%data);
    }
    $cube->rollup;
    mkdir('t');    
    mkdir('t/tcr');
    mkdir('t/tcr/0');
    mkdir('t/tcr/1');
    mkdir('t/tcr/2');
    
    $cube->commit('t/tcr/0');
    my $conn = DataCube::Connection->new('t/tcr/0');
    
    $cube->report('t/tcr/1');
    $conn->report('t/tcr/2');
    
    my $utils = DataCube::FileUtils->new;
    my @dir = $utils->dir('t/tcr/1');
    for(@dir){
        my $d1 = file_md5("t/tcr/1/$_");
        my $d2 = file_md5("t/tcr/2/$_");
        return 0 unless $d1 eq $d2;
    }
    return un('t/tcr');
}

sub th {
    my $schema = DataCube::Schema->new;
    $schema->add_dimension('country');
    $schema->add_dimension('product');
    $schema->add_dimension('salesperson');
    $schema->add_hierarchy('year','quarter','month','day');
    $schema->add_measure('sum','units_sold');
    $schema->add_measure('sum','dollar_volume');
    $schema->add_measure('average','price_per_unit');
    my $cube = DataCube->new($schema);
    my @data = example_sales_data();
    
    for(my $i = 0; $i < @data; $i++){  
        my $date  = $data[$i][0];
        my($month,$day,$year) = split/\//,$date;
        my $quarter = $month > 0 && $month < 4  ? 'Q1' :
                      $month > 3 && $month < 7  ? 'Q2' :
                      $month > 6 && $month < 10 ? 'Q3' :
                      $month > 9 && $month < 13 ? 'Q4' : '';
        my %data = ();
        $data{year}           = $year;
        $data{quarter}        = $quarter;
        $data{month}          = sprintf("%02d",$month);
        $data{day}            = sprintf("%02d",$day);
        $data{country}        = $data[$i][1];
        $data{salesperson}    = $data[$i][2];
        $data{product}        = $data[$i][3];
        $data{units_sold}     = $data[$i][4];
        $data{price_per_unit} = $data[$i][5];
        $data{dollar_volume}  = $data[$i][6];
        $cube->insert(\%data);
    }
    $cube->rollup;
    mkdir('t');    
    mkdir('t/tch');
    mkdir('t/tch/0');
    mkdir('t/tch/1');
    mkdir('t/tch/2');
    $cube->commit('t/tch/0');
    my $conn = DataCube::Connection->new('t/tch/0');    
    $cube->report_html('t/tch/1');
    $conn->report_html('t/tch/2');
    
    return un('t/tch');
}


sub pp {

    {
    	my $schema = DataCube::Schema->new;
    	$schema->add_dimension('a');
    	$schema->add_dimension('b');
	    $schema->add_dimension('c');
    	$schema->add_hierarchy('d','e');
    	$schema->add_measure('count');
    	my $cube = DataCube->new($schema);
    	my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
    	splice(@pending_levels, 0 ,1);
    	for(@pending_levels){
            my $level = $_;
 	    my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
	        my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
        	return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }
    
    {   
        my $schema = DataCube::Schema->new;
        $schema->add_dimension('a');
        $schema->add_dimension('b');
        $schema->add_dimension('c');
        $schema->add_strict_hierarchy('d' .. 'm');
        $schema->add_measure('count');
        my $cube = DataCube->new($schema);
        my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
        splice(@pending_levels, 0 ,1);
        for(@pending_levels){
            my $level = $_;
            my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
                my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
                return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }

    {   
        my $schema = DataCube::Schema->new;
        $schema->add_dimension('a');
        $schema->add_dimension('b');
        $schema->add_strict_dimension('c');
        $schema->add_hierarchy('d' .. 'm');
        $schema->add_measure('count');
        my $cube = DataCube->new($schema);
        my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
        splice(@pending_levels, 0 ,1);
        for(@pending_levels){
            my $level = $_;
            my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
                my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
                return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }

    {   
        my $schema = DataCube::Schema->new;
        $schema->add_dimension('a');
        $schema->add_dimension('b');
        $schema->add_dimension('c');
        $schema->add_strict_hierarchy('d' .. 'h');
        $schema->suppress_lattice_point('a','b','d','h');
        $schema->add_measure('count');
        my $cube = DataCube->new($schema);
        my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
        splice(@pending_levels, 0 ,1);
        for(@pending_levels){
            my $level = $_;
            my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
                my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
                return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }

   {
        my $schema = DataCube::Schema->new;
        $schema->add_dimension($_) for ('a' .. 'm');
        $schema->suppress_lattice_point('a' .. 'l');
        $schema->suppress_lattice_point('b' .. 'm');
        $schema->suppress_lattice_point('c' .. 'k');
        $schema->add_measure('count');
        my $cube = DataCube->new($schema);
        my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
        splice(@pending_levels, 0 ,1);
        for(@pending_levels){
            my $level = $_;
            my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
                my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
                return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }

    {
        my $schema = DataCube::Schema->new;
        $schema->add_dimension($_) for ('a' .. 'm');
        $schema->assert_lattice_point('a' .. 'l'); 
        $schema->assert_lattice_point('b' .. 'm');
        $schema->assert_lattice_point('c' .. 'k');
        $schema->add_measure('count');
        my $cube = DataCube->new($schema);
        my @pending_levels = sort { $b <=> $a } keys %{$cube->{controller}->{cube_stats}->{field_count}};
        splice(@pending_levels, 0 ,1);
        for(@pending_levels){
            my $level = $_;
            my @next_cubes = @{$cube->{controller}->{cube_stats}->{field_count}->{$level}};
            for(@next_cubes){
                my $next_cube_name = $_;
                my $possible_parents = $cube->{controller}->{cube_stats}->{possible_parents}->{$next_cube_name};
                return 0 unless $possible_parents && ref($possible_parents) =~ /^array$/i && @$possible_parents > 0 ;
            }
        }
    }

    {
        for(1..10){
            my $lim = $_;
            my $schema = DataCube::Schema->new;
            $schema->add_dimension($_) for (0 .. $lim);
            $schema->add_measure('sum','x');
            my $cube = DataCube->new($schema);
            my $total;
            for(0..99){
                my %data;
                for(0 .. $lim){
                   $data{$_} = int(rand(3)) || '';
                }
                $data{x} = int(rand(10));
                $total->{'overall'}        += $data{x};
                $total->{ $data{0} } += $data{x};
                $cube->insert(\%data);
            }
            $cube->rollup;
            my $cuba = $cube->{cube_store}->fetch('0');
            return 0 unless $cuba;
            use Data::Dumper;
            for(keys %{ $cuba->{cube}}){
                return 0 unless $cuba->{cube}->{$_}->{sum}->{x} == $total->{$_};
            }
            my $cubx = $cube->{cube_store}->fetch('overall');
            for(keys %{ $cubx->{cube}}){
                return 0 unless $cubx->{cube}->{$_}->{sum}->{x} == $total->{'overall'};
            }
        }
    }
    return 1;
}


sub lg {
    
    my $schema = DataCube::Schema->new;
    
    $schema->add_dimension('site');
    $schema->add_dimension('size');
    $schema->add_dimension('network');
    $schema->add_strict_dimension('country');
    $schema->add_strict_hierarchy('month','day');
    $schema->add_measure('key_count');
    $schema->add_measure('count','uniques');
    $schema->add_measure('multi_count','uniques');
    $schema->suppress_lattice_point('network','site','country','month');
    $schema->suppress_lattice_point('network','size','country','month');
    $schema->suppress_lattice_point('network','site','country','month','day');
    $schema->suppress_lattice_point('network','size','country','month','day');

    my $cube   = DataCube->new($schema);
    
    my $data   = fcon('lg');
    my @data   = split/\n/,$data;
    my @fields = qw(country day month network site size uniques);
    my %counts;
    
    for(@data){
        my @row = split/\^/;
        my %data;
        @data{@fields} = @row;
        $cube->insert(\%data);
        my $key = join("\t",@row[0,2]);
        $counts{$key}{$row[6]}++;
    }
    
    $cube->rollup;
    
    my $name = join("\t",@fields[0,2]);
    my $hash = $cube->{cube_store}->{cubes}->{$name}->{cube};

    return 0 unless scalar(keys(%$hash)) == scalar(keys(%counts));
    
    for(keys %counts){
        my $key = $_;
        my $hand_count = $counts{$key};
        my $cube_count = $hash->{$key}->{count}->{uniques};
        my $cube_multi = $hash->{$key}->{multi_count}->{uniques};
        
        return 0 unless
            scalar(keys(%$cube_count)) ==
            scalar(keys(%$hand_count)) &&
            scalar(keys(%$hand_count)) ==
            scalar(keys(%$cube_multi));
            
        for(keys %$hand_count){
            my $user           = $_;
            my $hand_sesh = $hand_count->{$user};
            my $cube_sesh = $cube_multi->{$user};
            return 0 unless $hand_sesh == $cube_sesh;
        }
    }
    return 1;
}

sub vg {
    my $schema = DataCube::Schema->new;
    
    $schema->add_dimension('players');
    $schema->add_dimension('platform');
    $schema->add_dimension('publisher');
    
    $schema->add_measure('key_count');
    $schema->add_measure('count','title');
    
    my $cube   = DataCube->new($schema);
    
    my $data   = fcon('vg');
    my @data   = split/\n/,$data;
    my @fields = qw(platform players publisher title);
    
    my %data;
    
    shift @data;
    
    my(%c3,%c4,%c5);
    
    for(@data){
        my @row = split/\^/,$_,-1;
        $row[5] =~ s/(\d+),/$1/g if $row[5] =~ /^[\d,]+$/; 
        for(@row){$_ = '(blank)' unless defined $_ && length $_}
        @data{@fields} = @row[0,5,2,1];
        my $k3 = join("\t",@row[0,2]);
        my $k4 = join("\t",@row[0,5]);
        my $k5 = $row[0];
        $c3{k}{$k3}++;
        $c4{k}{$k4}++;
        $c5{k}{$k5}++;
        $c3{c}{$k3}{$row[1]} = undef;
        $c4{c}{$k4}{$row[1]} = undef;
        $c5{c}{$k5}{$row[1]} = undef;
        $cube->insert(\%data);
    }
    
    $cube->rollup;
    
    my $vg3 = fcon('vg3');
    my $vg4 = fcon('vg4');
    my $vg5 = fcon('vg5');
    
    my @vg3 = split/\n/,$vg3;
    my @vg4 = split/\n/,$vg4;
    my @vg5 = split/\n/,$vg5;
    
    my(%vg3,%vg4,%vg5);
    
    my $vg3cube = $cube->{cube_store}->{cubes}->{"platform\tpublisher"}->{cube};
    my $vg4cube = $cube->{cube_store}->{cubes}->{"platform\tplayers"}->{cube};
    my $vg5cube = $cube->{cube_store}->{cubes}->{"platform"}->{cube};
    
    for(@vg3){
        my @row = split/\^/,$_,-1;
        my $v0  = $row[2];
        my $v1  = $c3{k}{join("\t",@row[1,0])};
        my $v2  = $vg3cube->{"$row[1]\t$row[0]"}->{key_count};
        return 0 unless $v0 == $v1;
        return 0 unless $v1 == $v2;
    }
    
    for(@vg4){
        my @row = split/\^/,$_,-1;
        my $k0  = join("\t",@row[0,1]);
        my $v0  = $row[2];
        my $v1  = $c4{k}{$k0};
        my $v2  = $vg4cube->{$k0}->{key_count};
        return 0 unless $v0 == $v1 && $v1 == $v2;
    }
    
    for(@vg5){
        my @row = split/\^/,$_,-1;
        my $v0  = $row[1];
        my $v1  = $c5{k}{$row[0]};
        my $v2  = $vg5cube->{$row[0]}->{key_count};
        return 0 unless $v0 == $v1 && $v1 == $v2;
    }
    
    for(keys %{$c3{c}}){
        my $v0 = scalar(keys(%{$c3{c}{$_}}));
        my $v1 = scalar(keys(%{$vg3cube->{$_}->{count}->{title}}));
        return 0 unless $v0 == $v1;
    }
    
    for(keys %{$c4{c}}){
        my $v0 = scalar(keys(%{$c4{c}{$_}}));
        my $v1 = scalar(keys(%{$vg4cube->{$_}->{count}->{title}}));
        return 0 unless $v0 == $v1;
    }
    
    for(keys %{$c5{c}}){
        my $v0 = scalar(keys(%{$c5{c}{$_}}));
        my $v1 = scalar(keys(%{$vg5cube->{$_}->{count}->{title}}));
        return 0 unless $v0 == $v1;
    }
    
    return 1;
    
}

sub rd {
    my $schema = DataCube::Schema->new;
    
    $schema->add_dimension('symbol');
    $schema->add_hierarchy('p5','p4','p3','p2','p1');
    
    $schema->add_measure('key_count');
    
    $schema->add_measure('sum',    'seq_int');
    $schema->add_measure('sum',    'rnd_int');
    $schema->add_measure('sum',    'rnd_sgn');
    
    $schema->add_measure('average','seq_int');
    $schema->add_measure('average','rnd_int');
    $schema->add_measure('average','rnd_sgn');
    
    $schema->add_measure('product','rnd_flo');
    $schema->add_measure('product','rnd_sgn');
    
    my $digest = Digest::MD5->new;
    my $cube   = DataCube->new($schema);
    
    my $data;
    my $stats;
    
    my @syms = ('a'..'z','A'..'Z');
    
    $stats->{product}{rnd_flo} = 1;
    $stats->{product}{rnd_sgn} = 1;
    
    my $lim = 1e2;
    
    for(0..$lim){
        my $md5  = $digest->add(Time::HiRes::time)->hexdigest;
        my $sym  = $syms[int(rand(@syms))];
        my @data = ($_, $_**2, , rand() + 1);
        my $rand = rand;
        
        $data->{symbol}  = $sym;
        $data->{"p$_"}   = substr($md5,0,$_) for (1..5);
        $data->{seq_int} = $_ + 1;
        $data->{rnd_int} = int(rand(10));
        $data->{rnd_flo} = rand(2) + 2e-10;
        $data->{rnd_sgn} = $rand < .5 ? -1 : 1;
        
        $cube->insert($data);
        
        $stats->{sum}{seq_int} += $data->{seq_int};
        $stats->{sum}{rnd_int} += $data->{rnd_int};
        $stats->{sum}{rnd_sgn} += $data->{rnd_sgn};
            
        $stats->{product}{rnd_flo} *= $data->{rnd_flo};
        $stats->{product}{rnd_sgn} *= $data->{rnd_sgn};
        
        $stats->{average}{seq_int}{sum_total} += $data->{seq_int};
        $stats->{average}{rnd_int}{sum_total} += $data->{rnd_int};
        $stats->{average}{rnd_sgn}{sum_total} += $data->{rnd_sgn};
        
    }
    
    $stats->{average}->{$_}->{observations} = ($lim + 1) for(keys %{$stats->{average}});
    
    $cube->rollup;
    
    my $top_data = $cube->{cube_store}->{cubes}->{'overall'}->{cube}->{''};
    
    my %num_chx;
    
    for(qw(seq_int rnd_int rnd_sgn)){
        my $val1     = $top_data->{average}->{$_}->{sum_total} / $top_data->{average}->{$_}->{observations};
        my $val2     = $stats->{average}->{$_}->{sum_total}    / $stats->{average}->{$_}->{observations};
        $num_chx{$_} = abs($val1 - $val2);
    }
    
    $num_chx{pro_rnd_sgn} = abs($top_data->{product}->{rnd_flo} - $stats->{product}->{rnd_flo});
    
    my $stable = 1;
    for(keys %num_chx){
        $stable = 0 if $num_chx{$_} > 2e-5;
    }
    
    my $pass =
           $top_data->{sum}->{seq_int}     == $stats->{sum}{seq_int}
        && $top_data->{sum}->{rnd_int}     == $stats->{sum}{rnd_int}
        && $top_data->{sum}->{rnd_sgn}     == $stats->{sum}{rnd_sgn}
        && $top_data->{product}->{rnd_sgn} == $stats->{product}->{rnd_sgn}
        && $stable ? 1 : 0;

    return $pass;

}




sub df {
    my $schema    = DataCube::Schema->new;
    my $utils     = DataCube::FileUtils->new;
    my $fmerger   = DataCube::FileUtils::FileMerger->new;
    my $tmerger   = DataCube::FileUtils::TableMerger->new;
    my $formatter = DataCube::Report::Formatter->new; 
    my $digester  = Digest::MD5->new;
    
    $schema->add_dimension('site');
    $schema->add_dimension('size');
    $schema->add_dimension('network');
    $schema->add_strict_dimension('country');
    $schema->add_strict_hierarchy('month','day');
    $schema->add_measure('key_count');
    $schema->add_measure('count','uniques');
    $schema->add_measure('multi_count','uniques');
    $schema->suppress_lattice_point('network','site','country','month');
    $schema->suppress_lattice_point('network','size','country','month');
    $schema->suppress_lattice_point('network','site','country','month','day');
    $schema->suppress_lattice_point('network','size','country','month','day');

    my $cube1  = DataCube->new($schema);
    my $cube2  = DataCube->new($schema);
    my $cube3  = DataCube->new($schema);
    
    my $data   = fcon('lg');
    my @data   = split/\n/,$data;
    my @fields = qw(country day month network site size uniques);
    
    my $i = 0;
    for(@data){
        my @row = split/\^/;
        my %data;
        @data{@fields} = @row;
        $cube1->insert(\%data);
        if($i % 2){
            $cube2->insert(\%data);  
        } else {
            $cube3->insert(\%data);  
        }
        $i++;
    }

    mkdir('t');    
    mkdir('t/df');
    mkdir('t/df/1');
    mkdir('t/df/2');
    mkdir('t/df/3');
    
    $cube1->{base_cube}->commit('t/df/1');
	while(my $next_cube = $cube1->lazy_rollup){
        $next_cube->commit('t/df/1');
	}
    $cube2->{base_cube}->commit('t/df/2');
	while(my $next_cube = $cube2->lazy_rollup){
        $next_cube->commit('t/df/2');
	}
    $cube3->{base_cube}->commit('t/df/3');
	while(my $next_cube = $cube3->lazy_rollup){
        $next_cube->commit('t/df/3');
	}
    
    $cube1->sync('t/df/1');
    
    for( grep { /^[a-f0-9]+$/i } $utils->dir('t/df/1') ){
        return 0 unless -f("t/df/1/$_/.report");
        $formatter->sort_format("t/df/1/$_/.report");
        $tmerger->merge(
            source       => "t/df/2/$_",
            target       => "t/df/3/$_", 
        );
    }
    
    $cube3->sync('t/df/3');
    
    for( grep { /^[a-f0-9]+$/i } $utils->dir('t/df/3') ){
        return 0 unless -f("t/df/3/$_/.report");
        $formatter->sort_format("t/df/3/$_/.report");
    }

    for( grep { /^[a-f0-9]+$/i } $utils->dir('t/df/1') ){
        return 0 unless -f("t/df/1/$_/.report") && -f("t/df/3/$_/.report");
        my $digest1 = file_md5("t/df/1/$_/.report");
        my $digest3 = file_md5("t/df/3/$_/.report");
        
        return 0 unless $digest1 eq $digest3;
    }
    
    return un('t/df');
}



sub un {
    my $d = shift;
    return 1 unless -d($d);
    unlink_recursive($d);
}



























sub unlink_recursive {
    my $f   = shift;
    if(-f($f)){
        unlink $f || return 0;
        return 1;
    } else {
        my @dir = map{"$f/$_"}dir($f);    
        unlink_recursive($_) for @dir; 
        rmdir($f) || return 0;
        return 1;
    }
}

sub dmp{
    print Dumper \@_
}

sub fcon {
    my $f = shift;
    $f = -f($f) ? $f : "t/$f";
    sysopen(my $F, $f , O_RDONLY);
    sysread($F, my $x, -s($f));
    return $x;
}

sub rperm {
    my @x = @_;
    for my $i(0..$#x-1){
        my $rand = int rbet($i,$#x+1);
        ($x[$i],$x[$rand]) = ($x[$rand],$x[$i]);
    }@x
}

sub rbet{
    $_[0] + rand($_[1]-$_[0]);
}

sub dir {
    my $d = shift;
    opendir(my $D, $d) or die "cant open directory:\n$d\n$!\n";
    grep { /[^\.]/ } readdir($D);
}

sub file_md5 {
    my $file = shift;
    open(my $F, '<' , $file)
        or die "cant open file:\n$file\n$!\n";
    binmode($F);
    my $digest = Digest::MD5->new->addfile($F)->hexdigest;
    close($F);
    return $digest;
}

sub example_sales_data {
    my $data = '
      Date         Country   SalesPerson     Product     Units   Unit_Cost       Total
      3/15/2005         US       Sorvino      Pencil        56        2.99      167.44
      3/7/2006          US       Sorvino      Binder         7       19.99      139.93
      8/24/2006         US       Sorvino        Desk         3      275.00      825.00
      9/27/2006         US       Sorvino         Pen        76        1.99      151.24
      5/22/2005         US      Thompson      Pencil        32        1.99       63.68
      10/14/2006        US      Thompson      Binder        57       19.99     1139.43
      4/18/2005         US       Andrews      Pencil        75        1.99      149.25
      4/10/2006         US       Andrews      Pencil        66        1.99      131.34
      10/31/2006        US       Andrews      Pencil       114        1.29      147.06
      12/21/2006        US       Andrews      Binder        28        4.99      139.72
      2/26/2005         CA          Gill         Pen        51       19.99     1019.49
      1/15/2006         CA          Gill      Binder        46        8.99      413.54
      5/14/2006         CA          Gill      Pencil        94        1.29      121.26
      5/31/2006         CA          Gill      Binder       102        8.99      916.98
      9/10/2006         CA          Gill      Pencil        98        1.29      126.42
      2/9/2005          UK       Jardine      Pencil       125        4.99      623.75
      5/5/2005          UK       Jardine      Pencil        90        4.99      449.10
      3/24/2006         UK       Jardine      PenSet        76        4.99      379.24
      11/17/2006        UK       Jardine      Binder        39        4.99      194.61
      12/4/2006         UK       Jardine      Binder        94       19.99     1879.06
      1/23/2005         US        Kivell      Binder        50       19.99      999.50
      11/25/2005        US        Kivell      PenSet        96        4.99      479.04
      6/17/2006         US        Kivell        Desk         5      125.00      625.00
      8/7/2006          US        Kivell      PenSet        42       23.95     1005.90
      6/25/2005         UK        Morgan      Pencil        90        4.99      449.10
      10/5/2005         UK        Morgan      Binder        28        8.99      251.72
      7/21/2006         UK        Morgan      PenSet        55       12.49      686.95
      9/1/2005          US         Smith        Desk         2      125.00      250.00
      12/12/2005        US         Smith      Pencil        67        1.29       86.43
      2/1/2006          US         Smith      Binder        87       15.00     1305.00
      7/12/2005         US        Howard      Binder        29        1.99       57.71
      4/27/2006         US        Howard         Pen        96        4.99      479.04
      1/6/2005          CA         Jones      Pencil        95        1.99      189.05
      4/1/2005          CA         Jones      Binder        76        4.99      379.24
      6/8/2005          CA         Jones      Binder        60        8.99      539.40
      8/15/2005         US         Jones      Pencil        35        4.99      174.65
      9/18/2005         US         Jones      PenSet        16       15.99      255.84
      10/22/2005        US         Jones         Pen        64        8.99      575.36
      2/18/2006         CA         Jones      Binder         4        4.99       19.96
      7/4/2006          CA         Jones      PenSet        61        4.99      304.39
      7/29/2005         UK         Hogan      Binder        81       19.99     1619.19
      11/8/2005         UK         Hogan         Pen        12       19.99      239.88
      12/29/2005        UK         Hogan      PenSet        74       15.99     1183.26
  ';
  
    my @data = map { [ grep { /\S/ } split/\s+/] } grep { /\S/ } split/\n+/,$data;
    shift @data;
    return @data;
}





