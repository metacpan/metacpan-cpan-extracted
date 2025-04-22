
# config file parser and data access

package App::GUI::Juliagraph::Config;
use v5.12;
use warnings;
use File::HomeDir;
use File::Spec;
use App::GUI::Juliagraph::Config::Default;

my $file_name = File::Spec->catfile( File::HomeDir->my_home, '.config', 'juliagraph');
my $dir = '';

sub new {
    my ($pkg) = @_;
    my $data = -r $file_name
             ? load( $pkg, $file_name )
             : $ App::GUI::Juliagraph::Config::Default::data;
    bless { path => $file_name, data => $data };
}

sub load {
    my ($self, $file) = @_;
    my $data = {};
    open my $FH, '<', $file or return "could not read $file: $!";
    my $category = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/^\s*(\w+):\s*$/)          { $category = $1; $data->{$category} = []; }
        elsif (/^\s+-\s+(.+)\s*$/)        { push @{$data->{$category}}, $1;          }
        elsif (/^\s+\+\s+(\w+)\s*=\s*\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]/)
                                          { $data->{$category} = {} if ref $data->{$category} ne 'HASH';
                                            $data->{$category}{$1} = [$2, $3, $4];   }
        elsif (/^\s+\+\s+(\w+)\s*=\s*\[\s*(.+)\s*\]/)
                                          { $data->{$category} = {} if ref $data->{$category} ne 'HASH';
                                            $data->{$category}{$1} = [map {tr/ //d; $_} split /,/, $2] }
        elsif (/\s*(\w+)\s*=\s*(.+)\s*$/) { $data->{$1} = $2; $category =  '';}
    }
    close $FH;
    $data;
}

sub save {
    my ($self) = @_;
    my $data = $self->{'data'};
    my $file = $self->{'path'};
    open my $FH, '>', $file or return "could not write $file: $!";
    $" = ',';
    for my $key (sort keys %$data){
        my $val = $data->{ $key };
        if (ref $val eq 'ARRAY'){
            say $FH "$key:";
            say $FH "  - $_" for @$val;
        } elsif (ref $val eq 'HASH'){
            say $FH "$key:";
            say $FH "  + $_ = [ @{$val->{$_}} ]" for sort keys %$val;
        } elsif (not ref $val){
            say $FH "$key = $val";
        }
    }
    close $FH;
}


sub get_value {
    my ($self, $key) = @_;
    $self->{'data'}{$key} if exists $self->{'data'}{$key};
}

sub set_value {
    my ($self, $key, $value) = @_;
    $self->{'data'}{$key} = $value;
}

sub add_setting_file {
    my ($self, $file) = @_;
    $file = App::GUI::Juliagraph::Settings::shrink_path( $file );
    for my $f (@{$self->{'data'}{'last_settings'}}) { return if $f eq $file }
    push @{$self->{'data'}{'last_settings'}}, $file;
    shift @{$self->{'data'}{'last_settings'}} if @{$self->{'data'}{'last_settings'}} > 15;
}

1;
