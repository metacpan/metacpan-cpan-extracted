
# read and writ .ini files with settings of a drawing

package App::GUI::Juliagraph::Settings;
use v5.12;
use warnings;
use FindBin;
use File::Spec;

sub load {
    my ($file) = @_;
    return unless defined $file;
    $file = expand_path( $file );
    my $data = {};
    open my $FH, '<', $file or return "could not read $file: $!";
    my $cat = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/\s*\[(\w+)\]/)           { $cat = $1 }
        elsif (/\s*(\w+)\s*=\s*(.+)\s*$/){ $data->{$cat}{$1} = $2 }
    }
    close $FH;
    $data;
}

sub write {
    my ($file, $data) = @_;
    open my $FH, '>', $file or return "could not write $file: $!";
    for my $main_key (sort keys %$data){
        say $FH "\n  [$main_key]\n";
        my $subhash = $data->{$main_key};
        next unless ref $subhash eq 'HASH';
        for my $key (sort keys %$subhash){
            say $FH "$key = $subhash->{$key}";
        }
    }
    close $FH;
    0;
}

sub ensure_file_ending {
    my ($file, $ending)  = @_;
    my $ret = $file;
    $ret;
}

sub extract_dir {
    my ($path)  = @_;
    my ($volume, $dir, $file) = File::Spec->splitpath( $path );
    $path = File::Spec->catdir( $volume, $dir );
    shrink_path( $path );
}

sub shrink_path {
    my ($path)  = @_;
    my $i = index($path, $FindBin::Bin );
    $path = '.' . substr( $path, length $FindBin::Bin) if $i > -1;
    $i = index($path, $ENV{HOME} );
    $path = '~' . substr( $path, length $ENV{HOME}) if $i > -1;
    $path;
}

sub expand_path {
    my ($path)  = @_;
    $path = File::Spec->catdir( $FindBin::Bin, substr( $path, 1) ) if substr($path, 0,1) eq '.';
    $path = File::Spec->catdir( $ENV{HOME}, substr( $path, 1) ) if substr($path, 0,1) eq '~';
    $path;
}


sub are_equal {
    my ($h1, $h2)  = @_;
    return 0 unless ref $h1 eq 'HASH' and ref $h2 eq 'HASH';
    for my $key (keys %$h1){
        next if not ref $h1->{$key} and exists $h2->{$key} and not ref $h2->{$key} and $h1->{$key} eq $h2->{$key};
        next if are_equal( $h1->{$key}, $h2->{$key} );
        return 0;
    }
    1;
}

sub clone {
    my ($settings)  = @_;
    return unless ref $settings eq 'HASH';
    {map { $_ => {%{$settings->{$_}}} } keys %$settings};
}




1;
