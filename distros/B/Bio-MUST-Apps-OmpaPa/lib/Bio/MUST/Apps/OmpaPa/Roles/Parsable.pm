package Bio::MUST::Apps::OmpaPa::Roles::Parsable;
# ABSTRACT: Parsable Moose role for search report objects
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::MUST::Apps::OmpaPa::Roles::Parsable::VERSION = '0.251770';
use Moose::Role;

use autodie;
use feature qw(say);
use version;

use Smart::Comments '###';

use Carp;
use Const::Fast;
use FileHandle;
use File::Temp;
use List::AllUtils qw(sum);
use Path::Class qw(file);
use POSIX;
use Text::Table;
use Template;
use File::Find::Rule;
use Sort::Naturally;
use File::Basename;
use Scalar::Util qw(looks_like_number);

use IO::Prompter [
    -verbatim,
    -style => 'blue strong',
    -must  => { 'be a string' => qr{\S+}xms }
];

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Drivers::Blast::Database';

use Bio::MUST::Apps::OmpaPa::Types;
use aliased 'Bio::MUST::Apps::OmpaPa::Parameters';

requires 'file', 'collect_hits';

# TODO: update attribute names to match interface
# TODO: break up long lines
# TODO: refine code layout

has 'database' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::File',
    coerce   => 1,
);

has 'scheme' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Taxonomy::ColorScheme',
);

has 'extract_seqs' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

has 'extract_taxs' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

has 'parameters' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Apps::OmpaPa::Parameters',
    lazy     => 1,
    coerce   => 1,
    builder  =>  '_build_parameters',
    handles   => qr{.*}xms,
);

has 'restore_last_param' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

has 'nb_org' => (
    is       => 'ro',
    isa      => 'Num',
);

has 'align' => (
    is       => 'ro',
    isa      => 'Num',
);

has 'gnuplot_term' => (
    is      => 'ro',
    isa     => 'Str',
);

has 'gnuplot_vers' => (
    is       => 'ro',
    isa      => 'version',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_gnuplot_vers',
);

# TODO: switch to coercions? what about Stash?

has '_blastdb' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Drivers::Blast::Database',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_blastdb',
);

has '_hits' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[HashRef[Any]]',
    init_arg => undef,
    lazy     => 1,
    builder  => 'collect_hits',
    handles  => {
       count_hits => 'count',
         all_hits => 'elements',
      filter_hits => 'grep',
         map_hits => 'map',
    },
);

has '_coeffs' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[HashRef[Any]]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_coeffs',
    handles  => {
     count_coeffs => 'count',
       all_coeffs => 'elements',
       get_coeffs => 'get',
    },
);

has '_selection' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[HashRef[Any]]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_selection',
    clearer  => '_clear_selection',
    writer   => '_set_selection',
    handles  => {
       count_selection => 'count',
         all_selection => 'elements',
      filter_selection => 'grep',
         map_selection => 'map',
    },
);

has '_filter' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Any]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_filter',
    clearer  => '_clear_filter',
    writer   => '_set_filter',
    handles  => {
     count_filter => 'count',
       all_filter => 'elements',
       get_filter => 'get',
    },
);

has '_avg_len' => (          # average length of top-25% hits
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_avg_len',
);

has $_ . '_file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_file',
) for qw(idl fas tax json list);

has $_ . '_param_file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_param_file',
) for qw(last new);

has '_data_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_data_handle',
    handles  => {
        _data_file => 'filename',
    },
);

has '_plot_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_plot_handle',
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_blastdb {
    return Database->new( file => shift->database );
}

sub _build_idl_file {
    return file( change_suffix( shift->new_param_file, '.idl' ) );
}

sub _build_fas_file {
    return file( change_suffix( shift->new_param_file, '.fasta' ) );
}

sub _build_tax_file {
    return file( change_suffix( shift->new_param_file, '.tax' ) );
}

sub _build_list_file {
    return file( change_suffix( shift->new_param_file, '.list' ) );
}

sub _build_json_file {
    return shift->new_param_file;
}

sub _build_new_param_file {
    my $self = shift;

    my $filename = $self->last_param_file;
    my ($basename, $dir, $suf) = fileparse( $filename, '.json' );
    ($basename, $dir, $suf) = fileparse( $self->file, qr{ \.[^.]* }xms )
        unless ($basename); # if first time
    my @parts = split '-', $basename;
    # default if it's the first time
    my $file = join '-', @parts;
    my $new_num = 1;

    my $num = pop @parts;
    if (looks_like_number( $num )){
        $new_num = $num + 1;
        $file = join '-', @parts;
    }

    my $new_file = join '.', (join '-', $file, $new_num), 'json';

    return file( $dir, $new_file );
}

sub _build_last_param_file {
    my $self = shift;

    my ($file, $dir, $suf) = fileparse( $self->file, qr{ \.[^.]* }xms );
    my @files = File::Find::Rule->file()
                                ->name( $file . '*.json' )
                                ->in( $self->file->dir );
    my @sorted = nsort( @files );

    # because File::Find::Rule goes recursively in directories
    # use the directory of entry file
    my @finalsort;

    FINALSORT:
    for my $f (@sorted) {
        my @parts = split m{/}xms, $f;
        if ("$parts[0]/" eq $dir) {
            push @finalsort, $f;
            next FINALSORT;
        }
        push @finalsort, $f if @parts < 2;
    }

    return file( $finalsort[-1] );
}

sub _build_avg_len {
    my $self = shift;

    # TODO: change: 10 bins eval + mean length // idem but length alignment
    # compute average length of the top-25% hits
    my $quarter = ceil( $self->count_hits / 4 );
    my @lengths = $self->map_hits( sub { $_->{'len'} } );
    my $avg_len = sum( @lengths[ 0 .. $quarter-1 ] ) / $quarter;

    return $avg_len;
}

sub _build_coeffs {
    my $self = shift;

    my %count_for;
    my %coeffs_for;

    for my $hit ($self->all_hits) {
        my $org = (split m{\|}xms, $hit->{acc})[0];
        $count_for{$org}++;

        my $coeff_len = $hit->{len} / $hit->{qlen};
        my $coeff_hmm = ( $hit->{hmm_to} - $hit->{hmm_from} +1 ) / $hit->{qlen};

        my ($index, $label) = $self->scheme
            ? $self->scheme->icol( $hit->{acc} ) : (undef, undef);

        # TODO: debug this: GCA_010025385.1
#         unless (defined $index) {
#             ### $hit
#             ### test: $self->scheme->icol( $hit->{acc} )
#         }

        $coeffs_for{ $hit->{acc} } = {
            org       => $org,
            count     => $count_for{$org},
            max_count => undef,
            coeff_len => sprintf("%.3f", $coeff_len),
            align     => sprintf("%.3f", $coeff_hmm),
            tax       => $label,
            index_tax => $index,
        };
    }

    for my $hit ($self->all_hits) {
        $coeffs_for{$hit->{acc}}{max_count}
            = $count_for{$coeffs_for{$hit->{acc}}{org}};
    }

    return \%coeffs_for;
}

sub _build_data_handle {
    my $self = shift;

    # open anonymous temporary file...
    # ... and ensures immediate communication with gnuplot
    my $data_handle = File::Temp->new(SUFFIX => '.dat', UNLINK => 1);

    # write pairs of -log10(evalue) / length as data points
    for my $hit ($self->all_hits) {

        my $info_for = $self->get_coeffs( $hit->{acc} );
        #### $info_for

        if ($self->scheme) {
            say {$data_handle} join "\t", _eval2log10( $hit->{exp} ),
                $hit->{len}, $info_for->{count}, $info_for->{align},
                $info_for->{coeff_len}, $info_for->{index_tax};
        }

        else {
            say {$data_handle} join "\t", _eval2log10( $hit->{exp} ),
                $hit->{len}, $info_for->{count}, $info_for->{align},
                $info_for->{coeff_len};
        }

    }

    return $data_handle;
}

sub _build_parameters {
    my $self = shift;

    if ($self->restore_last_param) {
        return Parameters->load( $self->last_param_file->stringify );
    }

    if ($self->align && $self->nb_org) {
        return Parameters->new( min_cov => $self->align,
                               max_copy => $self->nb_org );
    }

    return Parameters->new();
}

sub _build_gnuplot_vers {
    my $self = shift;

    # determine gnuplot version
    # TODO: doc OUM_GNUPLOT_EXEC
    my $pgm = $ENV{OUM_GNUPLOT_EXEC} // 'gnuplot';
    my ($version) = qx{$pgm --version} =~ m/gnuplot \s+ (\S+)/xms;
    ### gnuplot version: $version
    ### gnuplot terminal: $self->gnuplot_term

    return version->parse($version);
}

sub _build_plot_handle {
    my $self = shift;

    # open a gnuplot subprocess...
    # ... and ensures that commands are immediately processed
    # TODO: doc OUM_GNUPLOT_EXEC
    my $pgm = $ENV{OUM_GNUPLOT_EXEC} // 'gnuplot';
    open my $plot_handle, '|-', $pgm;
    $plot_handle->autoflush;

    return $plot_handle;
}

## use critic


sub select_bounds {
    my $self = shift;

    # configure display to allow interactive bound selection
    # TODO: handle a dumb terminal? this requires manually handling zooming
    $self->_setup_gnuplot;

    # output help message to console
    my $msg = "When satisfied with your selection, press 'Return' in the console";
    chomp $msg;
    my $ans = prompt $msg, -def => 'Y';

    # recover newly defined bounds from gnuplot subprocess
    $self->_update_bounds;
    $self->_clear_selection;
    $self->_set_selection($self->_build_selection);
    $self->_clear_filter;
    $self->_set_filter($self->_build_filter);

    return;
}

sub change_filter {
    my $self = shift;
    my $ans;
    # TODO: update wording to match main script
    do {
        $ans = prompt "Would you like to change the limit for filtering the",
                      -menu => { 'number of gene in one organism' => 'O',
                                 'alignment' => 'A',
                                 'that is OK, thanks' => 'N' },
                      '>';
        my $msg = "Type your new filtering limit";

        if ($ans eq 'O') {
            my $ans_org = prompt $msg, -n;
            #$self->nb_org($ans_org);
            $self->set_max_copy($ans_org);
        }

        elsif ($ans eq 'A') {
            my $ans_align = prompt $msg, -n;
            #$self->align($ans_align);
            $self->set_min_cov($ans_align);
        }

    } while ($ans ne 'N');

    return;
}

# TODO: only for bounds => should change name
sub _build_selection {
    my $self = shift;

    # ensure that a (valid) bounding-box is in use
    croak 'Error: undefined hit bounding-box'
        unless defined $self->max_len;

    # dynamically filter hits based on current bounds
    my @selection = $self->filter_hits( sub {
            _eval2log10( $_->{'exp'} ) >= $self->min_eval
         && _eval2log10( $_->{'exp'} ) <= $self->max_eval
         &&              $_->{'len'}   >= $self->min_len
         &&              $_->{'len'}   <= $self->max_len
    } );

    return \@selection;
}


sub _build_filter {
    my $self = shift;

    my $nb_org = $self->max_copy;
    my $align  = $self->min_cov;
    my %filter_for;

    for my $hit ($self->all_selection) {
        if ( ( $self->get_coeffs($hit->{acc}) )->{align} >= $align
          && ( $self->get_coeffs($hit->{acc}) )->{count} <= $nb_org ) {
            $filter_for{$hit->{acc}} = '*';
        }
    }

    return \%filter_for;
}

sub list_selection {
    my $self = shift;
    my $option = shift;

    # setup table of selected hits
    my $table = Text::Table->new( qw(keep accession description length evalue
                                     count max alignment ratio_length) );

    if ($self->scheme) {
        $table = Text::Table->new( qw(keep accession description length evalue
                                count max alignment ratio_length taxonomy) );
    }

    # fill-in table
    if ($option eq 'all') {
        $table->load( map {
            [ $self->get_filter( $_->{acc} ),
              $_->{acc},
              @{$_}{ qw(dsc len exp) },
              @{ $self->get_coeffs( $_->{acc} ) }{ qw(count max_count align
                                                      coeff_len tax) } ]
        } $self->all_selection );
    }

    elsif ($option eq 'keep') {

        for my $hit ($self->all_selection) {

            if ($self->get_filter( $hit->{acc} )) {
                $table->load( [ $self->get_filter( $hit->{acc} ),
                                $hit->{acc},
                                @{$hit}{ qw(dsc len exp) },
                                @{ $self->get_coeffs( $hit->{acc} ) }{ qw(count
                                        max_count align coeff_len tax) } ] );
            }
        }
    }
    # output table
    my $selec = $table->rule('=') . $table->title . $table->rule('-')
              . $table->body . $table->rule('=');

    return $selec;
}


sub save_selection {
    my $self = shift;
    $self->parameters->store( $self->json_file->stringify );

    ### save_selection and parameters: $self->json_file->{file}
    # write file of accession (or GI) numbers
    my @ids;

    for my $selec ($self->all_selection) {

        if ( $self->get_filter( $selec->{acc} ) ) {
            push @ids, $selec->{acc};
        }
    }

    $self->idl_file->spew( join("\n", @ids) . "\n" );

    $self->list_file->spew( $self->list_selection('keep') );

    # optionally write file of seqs
    if ($self->extract_seqs) {
        my $seqs = $self->fetch_seqs( \@ids );

        # fix ids returned by blastdbcmd
        # TODO: consider fixing this in Bio::MUST::Drivers or in Stash
        for my $seq_id ( $seqs->all_seq_ids ) {
            ( my $full_id = $seq_id->full_id )
                =~ s/lcl\| | \s unnamed \s protein \s product//xmsg;
            $seq_id->_set_full_id($full_id);
        }
        # TODO: fix this
        #$seqs->store_fasta( $self->fas_file );
        my @new_seqs = $seqs->all_seqs;
        my $ali = Ali->new( seqs => \@new_seqs );
        #my $ali = Ali->new( seqs => $seqs );
        $ali->store_fasta( $self->fas_file );
    }

    if ($self->extract_taxs) {
        my @labels = map { $self->scheme->classify($_) // "undef" } @ids;
        $self->tax_file->spew( join("\n", @labels) . "\n" );
    }

    return;
}


sub fetch_seqs {
    my $self = shift;
    my $ids  = shift;

    return $self->_blastdb->blastdbcmd($ids);
}

sub _setup_gnuplot {
    my $self = shift;

    # fill-in command template with relevant object attributes

    my $template = $self->_template_gnuplot;

    my %longcol_for = ( O => 'organisms',
                        T => 'taxonomy',
                        A => 'alignment',
                        G => 'global / alignment');

    # get variables for organism coloration
    my $org_col = $self->_org_col;
    my $coloration = 'O';

    # get variables for coefficients coloration
    my $coeff_col = $self->_coeff_col;

    # get variables for taxonomic coloration if asked
    my $tax_col;

    if ($self->scheme) {
        $tax_col = $self->_tax_col;
        $coloration = 'T';
    }

    #### data: $self->_data_file

    my $ans = 'Y';
    my $explaination;

    COLORS:
    while (uc($ans) ne 'N') {

        # set variables given the coloration asked
        my $col_vars = $self->_set_col_variables( $coloration, $org_col,
                                                  $coeff_col, $tax_col );

        my $global = $coloration eq 'G' ? $self->max_copy : undef;
        my $dt = $self->gnuplot_vers >= version->parse(5) ? q{dt "-"} : q{};

        my $tt = Template->new;
        my $vars = {
            term       => $self->gnuplot_term,
            report     => $self->file,
            avg_len    => int( $self->_avg_len ),   # no fractional length
            data_file  => $self->_data_file,
            palette    =>  $col_vars->{palette},
            range      =>  $col_vars->{color_n},
            tic        =>  $col_vars->{tic},
            column     =>  $col_vars->{column},
            limit      =>  $col_vars->{limit},
            comparison =>  $col_vars->{comparison},
            top        => $coeff_col->{top},
            bottom     => $coeff_col->{bottom},
            qlen       => $coeff_col->{qlen},
            coloration => $longcol_for{$coloration},
            global     => $global,
            dt         => $dt,
        };

        # bug when "Undo": have to change colors twice to be correct (sometimes)
        # TODO: fix that bug
        my $cmds;
        $tt->process(\$template, $vars, \$cmds)
            or croak $tt->error(), "\n";

        #### $cmds

        # send completed commands to gnuplot subprocess
        print { $self->_plot_handle } $cmds;

        my $msg = "Which coloration information would you like? (If you do not want to change colors, press 'Return'.)";

        unless ($explaination) {
            $msg = <<'EOT';
Define the hit bounding-box using the mouse (button 3).
If needed, reset the zoom level by pressing the 'U' key in the plot window.
Press 'H' to get help for other hot keys.
Which coloration information would you like? (If you do not want to change colors, press 'Return'.)
EOT
            $explaination = 1;
        }

        if ($self->scheme) {
            $ans = prompt $msg,
                          -def => 'N',
                          -menu => { 'Organisms' => 'O',
                                     'Taxonomy'  => 'T',
                                     'Alignment' => 'A',
                                     'Global'    => 'G' },
                          '>';
        }

        else {
            $ans = prompt $msg,
                          -def => 'N',
                          -menu => { 'Organisms' => 'O',
                                     'Alignment' => 'A',
                                     'Global'    => 'G' },
                          '>';
        }

        $coloration = $ans;
    };

    return;
}

sub _coeff_col {
    my $self = shift;

    my $palette_hmm = "0 \t 'yellow', 0.5 \t 'green', 1 \t 'black'"; # 1 = perfectly aligned
    my $color_n_hmm = 1;
    my $tic_hmm = "\"0\" 0, \"0.2\" 0.2, \"0.4\" 0.4, \"0.6\" 0.6, \"0.8\" 0.8, \"1\" 1";

    # TODO: find another way (do it twice: here and in _build_data_handle)
    my $top;
    my $bottom;
    my $qlen;

    HIT:
    for my $hit ($self->all_hits) {
        $top = $hit->{qlen} * 1.5;
        $bottom = $hit->{qlen} * 0.5;
        $qlen = $hit->{qlen};
        last HIT if ($qlen);
    }

    my %return = (
        color_n_hmm => $color_n_hmm,
        palette_hmm => $palette_hmm,
        tic_hmm     => $tic_hmm,
        top         => $top,
        bottom      => $bottom,
        qlen        => $qlen
    );

    return \%return;
}

sub _org_col {
    my $self = shift;

    my @ids = map { $_->{acc} } $self->all_hits;
    my @orgs = map { (split m{\|}xms, $_)[0] } @ids;
    my %count_orgs;

    for my $org (@orgs) {
        $count_orgs{$org}++;
    }

    my $nb_org_tot = keys %count_orgs;
    my $max = (sort {$a <=> $b} values %count_orgs)[$nb_org_tot-1];
    my $color_n = $max;         # range scale palette
    # limit coloration: 3 (default) or more times the same organism in yellow
    my $limit = $self->max_copy;
    # if black: bug!
    my $palette = "0 \t 'black', 1 \t 'red', $limit \t 'yellow', $max \t 'yellow'";

    if ($limit > $max) {
        $palette = "0 \t 'black', 1 \t 'red', $max \t 'yellow'";

        if ($max == 1) {
            $palette = "0 \t 'black', 1 \t 'red'";
        }
    }

    my %return = (
        color_n  => $color_n,
        palette  => $palette,
    );

    return \%return;
}

sub _tax_col {
    my $self = shift;

    # make palette for legend
    my $scheme = $self->scheme;
    my $color_n = $scheme->count_colors;        # range scale palette
    my %color_for = $scheme->all_icols;
    #### %color_for

    # TODO: exclude black specs?
    # TODO: warn of dupe specs
    my %colorcode_for = (
                           0 => '#000000',      # unclassified hit = black
        map { $color_for{$_} => $_ } keys %color_for
    );
    #### %colorcode_for

    my @strings;
    my $inc = 0;
    for my $num ( sort {$a <=> $b} keys %colorcode_for ) {
        push @strings, ($num-$inc) . "\t \"" . $colorcode_for{$num} . q{"};
        $inc ||= $inc + 0.5;
        push @strings, ($num+$inc) . "\t \"" . $colorcode_for{$num} . q{"};
    }
    #### @strings
    my $palette = join q{,}, @strings;

    # make labels for legend
    my @names = $scheme->all_names;

    my @tics;
    for my $label (@names) {
        my $index = $self->scheme->icol_for( $scheme->color_for($label) );
        my $string = q{"} . $label . qq{" \t} . $index;
        push @tics, $string;
    }
    my $tic_str = join q{,}, @tics;

    my %return = (
        color_n  => $color_n + 0.5,
        palette  => $palette,
        tic      => $tic_str,
    );

    return \%return;
}

sub _template_gnuplot {
    my $self = shift;

    # different template given the coloration asked
    my $template = <<'EOT';
x = "-log10(evalue)"
y = "hit length"
[% IF print %]set terminal pdf enhanced font ",8"
set output "[% report %].[% suffix %]_[% coloration %].pdf"
[% ELSE %]set term [% term %] title "OmpaPa: [% report %]"
[% END %]set format "%.0f"
set mouse mouseformat x . ": %3.0f | " . y . ": %4.0f"
set size square
#set title "average length of top-25% hits: [% avg_len %]"
set title "Selected hits given hit length and evalue and with \n [% coloration %] coloration"
set grid x y
set xlabel x
set ylabel y
set arrow 1 from graph 0, first [% top %] to graph 1, first [% top %] nohead [% dt %]
set arrow 2 from graph 0, first [% bottom %] to graph 1, first [% bottom %] nohead [% dt %]
set arrow 3 from graph 0, first [% qlen %] to graph 1, first [% qlen %] nohead [% dt %] lc rgb "blue"
set cbrange[0:[% range %]]
[% IF tic %]set cbtics ([% tic %])
[% ELSE %]unset cbtics
set cbtics
[% END %]set palette defined ([% palette %])
[% IF print %][% IF global %][% IF all %]plot "[% data_file %]" using 1:2:[% column %] notitle with points pt 7 ps .2 palette
[% ELSE %]plot "[% data_file %]" using 1:($[% column %] [%comparison %]= [% limit %] && $3 <= [% global %] ? $2 : 1/0):[% column %] notitle with points pt 7 ps .2 palette[% END %]
[% ELSE %]plot "[% data_file %]" using 1:($[% column %] [%comparison %]= [% limit %] ? $2 : 1/0):[% column %] notitle with points pt 7 ps .2 palette[% END %]
[% ELSE %][% IF global %]plot "[% data_file %]" using 1:($[% column %] [%comparison %]= [% limit %] && $3 <= [% global %] ? $2 : 1/0):[% column %] notitle with points pt 7 ps 1 palette
[% ELSE %]plot "[% data_file %]" using 1:($[% column %] [%comparison %]= [% limit %] ? $2 : 1/0):[% column %] notitle with points pt 7 ps 1 palette[% END %][% END %]
EOT

    return $template;
}


sub _set_col_variables {
    my $self        = shift;
    my $coloration  = shift;
    my $org_col     = shift;
    my $coeff_col   = shift;
    my $tax_col     = shift;

    my $palette;
    my $color_n;
    my $tic;
    my $column;
    my $limit;
    my $comparison;

    if (uc($coloration) eq 'O') {
        $palette = $org_col->{palette};
        $color_n = $org_col->{color_n};
        $tic = undef;
        $column = 3;
        $limit = $self->max_copy;
        $comparison = "<";
    }

    elsif (uc($coloration) eq 'T') {
        $palette = $tax_col->{palette};
        $color_n = $tax_col->{color_n};
        $tic = $tax_col->{tic};
        $column = 6;
        $limit = '$6';
        $comparison = "=";
    }

    elsif (uc($coloration) eq 'A') {
        $palette = $coeff_col->{palette_hmm};
        $color_n = $coeff_col->{color_n_hmm};
        $tic = $coeff_col->{tic_hmm};
        $column = 4;
        $limit = $self->min_cov;
        $comparison = ">";
    }

    elsif (uc($coloration) eq 'G') {
        $palette = $coeff_col->{palette_hmm};
        $color_n = $coeff_col->{color_n_hmm};
        $tic = $coeff_col->{tic_hmm};
        $column = 4;
        $limit = $self->min_cov;
        $comparison = ">";
    }

    my $vars = {
        palette    => $palette,
        color_n    => $color_n,
        tic        => $tic,
        column     => $column,
        limit      => $limit,
        comparison => $comparison,
    };

    return $vars;
}

sub print_plot {
    my $self = shift;
    my $suf  = shift;
    my $all  = shift;

    my $template = $self->_template_gnuplot;

    my   $org_col = $self->_org_col;
    my $coeff_col = $self->_coeff_col;
    my @colorations = qw(O A G);

    my $tax_col;

    if ($self->scheme) {
        $tax_col = $self->_tax_col;
        push @colorations, 'T';
    }

    for my $coloration (@colorations) {
        my $col_vars = $self->_set_col_variables( $coloration, $org_col,
                                                  $coeff_col, $tax_col );

        my $global = $coloration eq 'G' ? $self->max_copy : undef;
        my $dt = $self->gnuplot_vers >= version->parse(5) ? q{dt "-"} : q{};

        my ($basename, $dir) = fileparse( $self->new_param_file, '.json' );
        my $report = join '', $dir, $basename;

        my $tt = Template->new;
        my $vars = {
            report     => $report,
            avg_len    => int( $self->_avg_len ),   # no fractional length
            data_file  => $self->_data_file,
            palette    =>  $col_vars->{palette},
            range      =>  $col_vars->{color_n},
            tic        =>  $col_vars->{tic},
            column     =>  $col_vars->{column},
            limit      =>  $col_vars->{limit},
            comparison =>  $col_vars->{comparison},
            top        => $coeff_col->{top},
            bottom     => $coeff_col->{bottom},
            qlen       => $coeff_col->{qlen},
            coloration => $coloration,
            suffix     => $suf,
            print      => 'Y',
            global     => $global,
            all        => $all,
            dt         => $dt,
        };

        my $print_cmds;
        $tt->process(\$template, $vars, \$print_cmds)
            or croak $tt->error(), "\n";

        #### $print_cmds

        # send completed commands to gnuplot subprocess
        print { $self->_plot_handle } $print_cmds;
    }

    return;
}

sub _update_bounds {
    my $self = shift;

    # ask gnuplot to export its bounds as currently defined
    my $bounds = $self->store_bounds;
    print { $self->_plot_handle } $bounds; # store bounds

    # restore bounds from freshly created bb_file
    $self->load_bounds;

    return;
}


# private subs

{
    const my $MAXLOG10 => 308;
    const my $LOG10    => log(10);

    sub _eval2log10 {
        my $eval = shift;

        return $eval == 0 ? $MAXLOG10
             : $eval >= 1 ? 0
             :             -log($eval)/$LOG10
        ;
    }
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::OmpaPa::Roles::Parsable - Parsable Moose role for search report objects

=head1 VERSION

version 0.251770

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
