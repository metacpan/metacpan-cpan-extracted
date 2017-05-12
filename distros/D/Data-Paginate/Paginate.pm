package Data::Paginate;

use strict;
use warnings;
use version;our $VERSION = qv('0.0.6');

use Carp ();
use POSIX ();
use Class::Std;
use Class::Std::Utils;

sub croak {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::croak(@_);
}

sub carp {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::carp(@_);
}

{ #### begin scoping "inside-out" class ##
        
#### manually set_ because they recalculate ##
#### needs manually set in BUILD ##

    my %total_entries             :ATTR('get' => 'total_entries', 'default' => '100');
    sub set_total_entries {
        my ($self, $digit, $checkonly) = @_;
        my $reftype        = ref $digit;

        carp('Argument to set_total_entries() must be a digit or an array ref') && return if $digit !~ m/^\d+$/ && $reftype ne 'ARRAY';
        return 1 if $checkonly;
        $total_entries{ ident $self } = $reftype eq 'ARRAY' ? @{ $digit } 
                                                            : $digit;
        $self->_calculate();
    }

    my %entries_per_page          :ATTR('get' => 'entries_per_page', 'default' => '10');
    sub set_entries_per_page { 
        my ($self, $digit, $checkonly) = @_; 
        carp('Argument to set_entries_per_page() must be a digit') && return
            if $digit !~ m/^\d+$/;   
        return 1 if $checkonly;
        $entries_per_page{ ident $self } = $digit;        
        $self->_calculate();
    }

    my %pages_per_set             :ATTR('get' => 'pages_per_set', 'default' => '10');
    sub set_pages_per_set { 
        my ($self, $digit, $checkonly) = @_; 
        carp('Argument to set_pages_per_set() must be a digit') && return 
           if $digit !~ m/^\d+$/;      
        return 1 if $checkonly;
        $pages_per_set{ ident $self } = $digit;     
        $self->_calculate();    
    }
    
    my %sets_per_set             :ATTR('get' => 'sets_per_set', 'default' => '10');
    sub set_sets_per_set { 
        my ($self, $digit, $checkonly) = @_; 
        carp('Argument to set_sets_per_set() must be a digit') && return
           if $digit !~ m/^\d+$/;      
        return 1 if $checkonly;
        $sets_per_set{ ident $self } = $digit;     
        $self->_calculate();    
    }

    my %current_page              :ATTR('get' => 'current_page', 'default' => '1');
    sub _set_current_page {     
        my ($self, $digit, $checkonly) = @_;               
        carp('Argument to _set_current_page() must be a digit') && return 
           if $digit !~ m/^\d+$/;         
        return 1 if $checkonly;
        $current_page{ ident $self } = $digit;               
        $self->_calculate();    
    }

    my %variable_entries_per_page :ATTR('get' => 'variable_entries_per_page', 'default' => {});
    sub set_variable_entries_per_page {
        my ($self, $hashref, $checkonly) = @_;
        carp('Argument to set_variable_entries_per_page() must be a hashref') && return 
            if ref $hashref ne 'HASH';
        for(keys %{ $hashref }) {
            carp('Non digit key in set_variable_entries_per_page() arg') && return
                if $_ !~ m/^\d+$/;
            carp("Non digit value in set_variable_entries_per_page() arg $_") && return 
                if $hashref->{$_} !~ m/^\d+$/;
        }
        return 1 if $checkonly;
        $variable_entries_per_page{ ident $self } = $hashref;
        $self->_calculate();
    }

#### manually set_ because they need input checked ##
#### needs manually set in BUILD ##

    my %ext_obj :ATTR('get' => 'ext_obj');
    sub set_ext_obj {
        my ($self, $obj) = @_;
        carp('Argument to set_ext_obj() must be an object') && return 
            if !ref $obj;
        $ext_obj{ ident $self } = $obj;
    }
    
    my %page_result_display_map :ATTR('get' => 'page_result_display_map', 'default' => {}); 
    sub set_page_result_display_map {
        my ($self, $hashref) = @_;
        carp('Argument to set_page_result_display_map() must be a hashref') && return 
            if ref $hashref ne 'HASH';
        $page_result_display_map{ ident $self } = $hashref;
    }

    my %set_result_display_map  :ATTR('get' => 'set_result_display_map', 'default' => {}); 
    sub set_set_result_display_map {
        my ($self, $hashref) = @_;
        carp('Argument to set_result_display_map() must be a hashref') && return 
            if ref $hashref ne 'HASH';
        $set_result_display_map{ ident $self } = $hashref;
    }

    my %result_display_map      :ATTR; # set 2 above, no get_:
    sub set_result_display_map {
        my ($self, $hashref) = @_;
        carp('Argument to set_result_display_map() must be a hashref') && return 
            if ref $hashref ne 'HASH';
        $page_result_display_map{ ident $self } = $hashref;
        $set_result_display_map{ ident $self } = $hashref;
    }

    my %html_line_white_space   :ATTR('get' => 'html_line_white_space', 'default' => '0'); 
    sub set_html_line_white_space {
        my ($self, $digit) = @_;
        carp('Argument to set_html_line_white_space() must be a digit') && return 
            if $digit !~ m/^\d+$/;
        $html_line_white_space{ ident $self } = $digit;
    }

    my %param_handler           :ATTR('get' => 'param_handler', 'default' => undef);
    sub set_param_handler {
        my ($self, $coderef) = @_;
        carp('Argument to set_param_handler() must be a code ref') && return 
            if ref $coderef ne 'CODE';
        $param_handler{ ident $self } = $coderef;
    }

    my %sets_in_rows            :ATTR('get' => 'sets_in_rows', 'default' => '0');         
    sub set_sets_in_rows {
        my ($self, $digit) = @_;
        carp('Argument to set_sets_in_rows() must be a digit') && return 
            if $digit !~ m/^\d+$/;
        $sets_in_rows{ ident $self } = $digit;
    }

#### get_ only since these are set only by _calulate() is done ##

    my %entries_on_this_page :ATTR('get' => 'entries_on_this_page');
    my %first_page           :ATTR('get' => 'first_page');           
    my %last_page            :ATTR('get' => 'last_page');            
    my %first                :ATTR('get' => 'first');     
    my %last                 :ATTR('get' => 'last');   
    my %previous_page        :ATTR('get' => 'previous_page'); 
    my %next_page            :ATTR('get' => 'next_page');    

    my %previous_set         :ATTR('get' => 'previous_set'); 
    my %next_set             :ATTR('get' => 'next_set');    
    my %pages_in_set         :ATTR('get' => 'pages_in_set');  

    my %last_set             :ATTR('get' => 'last_set');        
    my %first_set            :ATTR('get' => 'first_set');   
    my %last_page_in_set     :ATTR('get' => 'last_page_in_set');  
    my %first_page_in_set    :ATTR('get' => 'first_page_in_set'); 
    my %last_set_in_set     :ATTR('get' => 'last_set_in_set');  
    my %first_set_in_set    :ATTR('get' => 'first_set_in_set'); 
    my %current_set          :ATTR('get' => 'current_set');      

#### manually get_ only because they require handling ##

    sub get_pages_range {  
        my ($self) = @_;  
        return ($first{ ident $self } - 1 .. $last{ ident $self } - 1);
    }

    sub get_pages_splice { 
        my($self, $arrayref) = @_;
        return @{ $arrayref }[ $self->get_pages_range() ];
    }

    sub get_pages_splice_ref {
        my($self, $arrayref) = @_;
        return [ $self->get_pages_splice($arrayref) ];
    }

    sub get_firstlast {
        my ($self) = @_;
        return ($first{ ident $self }, $last{ ident $self }) if wantarray;
        return "$first{ ident $self },$last{ ident $self }";
    }

    sub get_lastfirst {
        my ($self) = @_;
        return ($last{ ident $self }, $first{ ident $self }) if wantarray;
        return "$last{ ident $self },$first{ ident $self }";
    }

    sub get_state_hashref {
        my ($self) = @_;
        my $hashref = eval $self->_DUMP(); 
        return $hashref->{ ref $self }; 
    }
    
    sub get_state_html {
        my ($self) = @_;
        require Data::Dumper::HTML;
        return Data::Dumper::HTML::dumper_html( $self->get_state_hashref() ) if defined wantarray;
        print Data::Dumper::HTML::dumper_html( $self->get_state_hashref() );
    }

#### get_ and set_ ##

    #### no default, handle in BUILD since it chokes on '&'
    my %pre_current_page       :ATTR('get' => 'pre_current_page', 'set' => 'pre_current_page', 'init_arg' => 'pre_current_page');
    my %pst_current_page       :ATTR('get' => 'pst_current_page', 'set' => 'pst_current_page', 'init_arg' => 'pst_current_page');
    my %pst_current_set        :ATTR('get' => 'pst_current_set', 'set' => 'pst_current_set', 'init_arg' => 'pst_current_set');
    my %pre_current_set        :ATTR('get' => 'pre_current_set', 'set' => 'pre_current_set', 'init_arg' => 'pre_current_set');

    my %total_entries_param    :ATTR('get' => 'total_entries_param', 'set' => 'total_entries_param', 'default' => 'te', 'init_arg' => 'total_entries_param');
    my %total_entries_verify_param_name  :ATTR('get' => 'total_entries_verify_param_name',  'set' => 'total_entries_verify_param_name',  'default' => 've', 'init_arg' => 'total_entries_param_verify_name');
    my %total_entries_verify_param_value :ATTR('get' => 'total_entries_verify_param_value', 'set' => 'total_entries_verify_param_value', 'default' => '',   'init_arg' => 'total_entries_param_verify_value');
    my %set_param              :ATTR('get' => 'set_param', 'set' => 'set_param', 'default' => 'st', 'init_arg' => 'set_param');
    my %next_page_html         :ATTR('get' => 'next_page_html', 'set' => 'next_page_html', 'default' => 'Next Page &rarr;', 'init_arg' => 'next_page_html');
    my %page_param             :ATTR('get' => 'page_param', 'set' => 'page_param', 'default' => 'pg', 'init_arg' => 'page_param');
    my %simple_nav             :ATTR('get' => 'simple_nav', 'set' => 'simple_nav', 'default' => '0', 'init_arg' => 'simple_nav');
    my %cssid_set              :ATTR('get' => 'cssid_set', 'set' => 'cssid_set', 'default' => 'set', 'init_arg' => 'cssid_set');
    my %cssid_not_current_page :ATTR('get' => 'cssid_not_current_page', 'set' => 'cssid_not_current_page', 'default' => 'notpg', 'init_arg' => 'cssid_not_current_page');
    my %cssid_current_set      :ATTR('get' => 'cssid_current_set', 'set' => 'cssid_current_set', 'default' => 'curst', 'init_arg' => 'cssid_current_set');
    my %pre_not_current_set    :ATTR('get' => 'pre_not_current_set', 'set' => 'pre_not_current_set', 'default' => '[', 'init_arg' => 'pre_not_current_set');
    my %pre_not_current_page   :ATTR('get' => 'pre_not_current_page', 'set' => 'pre_not_current_page', 'default' => '[', 'init_arg' => 'pre_not_current_page');
    my %pst_not_current_set    :ATTR('get' => 'pst_not_current_set', 'set' => 'pst_not_current_set', 'default' => ']', 'init_arg' => 'pst_not_current_set');
    my %prev_set_html          :ATTR('get' => 'prev_set_html', 'set' => 'prev_set_html', 'default' => '&larr; Prev Set', 'init_arg' => 'prev_set_html');
    my %one_set_hide           :ATTR('get' => 'one_set_hide', 'set' => 'one_set_hide', 'default' => '0', 'init_arg' => 'one_set_hide');
    my %no_prev_set_html       :ATTR('get' => 'no_prev_set_html', 'set' => 'no_prev_set_html', 'default' => '', 'init_arg' => 'no_prev_set_html');
    my %as_table               :ATTR('get' => 'as_table', 'set' => 'as_table', 'default' => '0', 'init_arg' => 'as_table');
    my %pst_not_current_page   :ATTR('get' => 'pst_not_current_page', 'set' => 'pst_not_current_page', 'default' => ']', 'init_arg' => 'pst_not_current_page');
    my %style                  :ATTR('get' => 'style', 'set' => 'style', 'init_arg' => 'style');
    my %no_prev_page_html      :ATTR('get' => 'no_prev_page_html', 'set' => 'no_prev_page_html', 'default' => '', 'init_arg' => 'no_prev_page_html');
    my %one_page_hide          :ATTR('get' => 'one_page_hide', 'set' => 'one_page_hide', 'default' => '0', 'init_arg' => 'one_page_hide');
    my %next_set_html          :ATTR('get' => 'next_set_html', 'set' => 'next_set_html', 'default' => 'Next Set &rarr;', 'init_arg' => 'next_set_html');
    my %one_set_html           :ATTR('get' => 'one_set_html', 'set' => 'one_set_html', 'default' => '', 'init_arg' => 'one_set_html');
    my %no_next_page_html      :ATTR('get' => 'no_next_page_html', 'set' => 'no_next_page_html', 'default' => '', 'init_arg' => 'no_next_page_html');
    my %cssid_current_page     :ATTR('get' => 'cssid_current_page', 'set' => 'cssid_current_page', 'default' => 'curpg', 'init_arg' => 'cssid_current_page');
    my %no_next_set_html       :ATTR('get' => 'no_next_set_html', 'set' => 'no_next_set_html', 'default' => '', 'init_arg' => 'no_next_set_html');
    my %prev_page_html         :ATTR('get' => 'prev_page_html', 'set' => 'prev_page_html', 'default' => '&larr; Prev Page', 'init_arg' => 'prev_page_html');
    my %cssid_page             :ATTR('get' => 'cssid_page', 'set' => 'cssid_page', 'default' => 'page', 'init_arg' => 'cssid_page');
    my %cssid_not_current_set  :ATTR('get' => 'cssid_not_current_set', 'set' => 'cssid_not_current_set', 'default' => 'notst', 'init_arg' => 'cssid_not_current_set');
    my %use_of_vars            :ATTR('get' => 'use_of_vars', 'set' => 'use_of_vars', 'default' => '0', 'init_arg' => 'use_of_vars');
    my %one_page_html          :ATTR('get' => 'one_page_html', 'set' => 'one_page_html', 'default' => '', 'init_arg' => 'one_page_html');

    my %of_page_string         :ATTR('get' => 'of_page_string', 'set' => 'of_page_string', 'default' => 'Page', 'init_arg' => 'of_page_string');
    my %of_set_string          :ATTR('get' => 'of_set_string',  'set' => 'of_set_string',  'default' => 'Set',  'init_arg' => 'of_set_string');
    my %of_of_string           :ATTR('get' => 'of_of_string',   'set' => 'of_of_string',   'default' => 'of',   'init_arg' => 'of_of_string');
    my %of_page_html           :ATTR('get' => 'of_page_html',   'set' => 'of_page_html',   'default' => '',     'init_arg' => 'of_page_html');
    my %of_set_html            :ATTR('get' => 'of_set_html',    'set' => 'of_set_html',    'default' => '',     'init_arg' => 'of_set_html');

    my %data_html_config       :ATTR('get' => 'data_html_config', 'init_arg' => 'data_html_config');
    my %perpage_html_config    :ATTR('get' => 'perpage_html_config', 'init_arg' => 'perpage_html_config');
    
    sub _calculate {
        my ($self) = @_;
        my $ident = ident $self;

        $current_page{$ident}          = ((($current_set{$ident} - 1) * $pages_per_set{$ident}) + 1)
            if defined $current_set{$ident} && $current_set{$ident} =~ m/^\d+$/ && $current_set{$ident} > 0;

        $first_page_in_set{$ident}     = 0; # set to 0 so its numeric 
        $last_page_in_set{$ident}      = 0; # set to 0 so its numeric

        my $per_page                   = exists $variable_entries_per_page{$ident}->{ $current_page{$ident} } 
            ? $variable_entries_per_page{$ident}->{ $current_page{$ident} } : $entries_per_page{$ident};

        my ($p,$r) = (0,0);
        for(keys %{ $variable_entries_per_page{$ident} }) {
            if($variable_entries_per_page{$ident}->{$_} =~ m/^\d+$/) {
                $p++;
                $r                    += int($variable_entries_per_page{$ident}->{$_});
            }
        }

        ($first_page{$ident}, $first{$ident}, $last{$ident}) = (1,0,0);
        $last_page{$ident}             = POSIX::ceil($p + (($total_entries{$ident} - $r) / $entries_per_page{$ident}));
        $current_page{$ident}          = $last_page{$ident} if $current_page{$ident} > $last_page{$ident};

        for($first_page{$ident} .. $current_page{$ident}) {
            if($current_page{$ident} == $last_page{$ident} && $_ == $current_page{$ident}) {
                $first{$ident}         = $last{$ident} + 1;
                $last{$ident}         += $total_entries{$ident} - $last{$ident};
            } 
            else {
                $last{$ident}         += exists $variable_entries_per_page{$ident}->{$_} 
                    ? $variable_entries_per_page{$ident}->{$_} : $entries_per_page{$ident};
            }
        }

        $first{$ident}                 = $last{$ident} - ($per_page - 1) if !$first{$ident};
        $previous_page{$ident}         = $current_page{$ident} - 1;
        $next_page{$ident}             = (($current_page{$ident} + 1) <= $last_page{$ident}) ? $current_page{$ident} + 1 : 0 ;
        $entries_on_this_page{$ident}  = ($last{$ident} - $first{$ident}) + 1;

        $of_page_string{$ident}        = 'Page' unless defined $of_page_string{$ident}; # why do we need this hack, what make Class::Std miss it ??
        $of_of_string{$ident}          = 'of' unless defined $of_of_string{$ident}; # why do we need this hack, what make Class::Std miss it ??
        $of_page_html{$ident}          = "$of_page_string{$ident} $current_page{$ident} $of_of_string{$ident} $last_page{$ident}";

        if($pages_per_set{$ident} =~ m/^\d+$/ && $pages_per_set{$ident} > 0) {
            $last_set{$ident}          = POSIX::ceil($last_page{$ident} / $pages_per_set{$ident});
            $current_set{$ident}       = POSIX::ceil($current_page{$ident} / $pages_per_set{$ident})
                unless defined $current_set{$ident} && $current_set{$ident} =~ m/^\d+$/ && $current_set{$ident} > 0;
            $current_set{$ident}       = $last_set{$ident} if $current_set{$ident} > $last_set{$ident};
            $first_page_in_set{$ident} = (($current_set{$ident} - 1) * $pages_per_set{$ident}) + 1;
            $last_page_in_set{$ident}  = ($first_page_in_set{$ident} + $pages_per_set{$ident}) - 1;
 
            $first_set{$ident}         = 1;
                        
            my $floor     = POSIX::floor($current_set{$ident}/$sets_per_set{$ident});
            my $floor_cmp = $current_set{$ident}/$sets_per_set{$ident};
            $first_set_in_set{$ident}  = ($floor * $sets_per_set{$ident}); 
            if($floor == $floor_cmp && $first_set_in_set{$ident} > 1) {
                $first_set_in_set{$ident} -= $sets_per_set{$ident};
                $first_set_in_set{$ident} += 1 if $first_set_in_set{$ident} > 1;
            }
            else {
                $first_set_in_set{$ident} += 1 if $first_set_in_set{$ident} > 1;
            }
            $last_set_in_set{$ident}   = ($first_set_in_set{$ident} + $sets_per_set{$ident});
            $last_set_in_set{$ident}  -= 1 if $first_set_in_set{$ident} > 1;           
            $last_set_in_set{$ident}   = $last_set{$ident} if $last_set_in_set{$ident} > $last_set{$ident};
 
            $previous_set{$ident}      = $current_set{$ident} - 1;
            $next_set{$ident}          = (($current_set{$ident} + 1) <= $last_set{$ident}) ? $current_set{$ident} + 1 : 0 ;
            $pages_in_set{$ident}      = $current_set{$ident} == $last_set{$ident} 
                ? $total_entries{$ident} - (($last_set{$ident} - 1) * $pages_per_set{$ident}) : $pages_per_set{$ident};

            $of_set_string{$ident} = 'Set' unless defined $of_set_string{$ident}; # why do we need this hack, what make Class::Std miss it ??
            $of_set_html{$ident}       = "$of_set_string{$ident} $current_set{$ident} $of_of_string{$ident} $last_set{$ident}";
        }
    }

    sub BUILD {
        my ($self, $ident, $arg_ref) = @_;

        #### since ATTR: chokes on default => ' with an & escaped or not... ##
        $pre_current_page{ $ident }          = exists $arg_ref->{pre_current_set}  ? $arg_ref->{pre_current_set} : q{&#187;};
        $pst_current_page{ $ident }          = exists $arg_ref->{pst_current_page} ? $arg_ref->{pst_current_page} : q{&#171;};
        $pre_current_set{ $ident }           = exists $arg_ref->{pre_current_set}  ? $arg_ref->{pre_current_set}  : q{&#187;};
        $pst_current_set{ $ident }           = exists $arg_ref->{pst_current_set}  ? $arg_ref->{pst_current_set}  : q{&#171;};

        $result_display_map{ $ident }        = exists $arg_ref->{result_display_map}      ? $arg_ref->{result_display_map}      : {};  
        $page_result_display_map{ $ident }   = exists $arg_ref->{page_result_display_map} ? $arg_ref->{page_result_display_map} : {};
        $set_result_display_map{ $ident }    = exists $arg_ref->{set_result_display_map}  ? $arg_ref->{set_result_display_map}  : {};

        $html_line_white_space{ $ident }     = exists $arg_ref->{html_line_white_space}   ? $arg_ref->{html_line_white_space}   : 0;
        $style{ $ident }                     = exists $arg_ref->{'style'} ? $arg_ref->{'style'} : $self->_default_style();

        $ext_obj{ $ident }                   = exists $arg_ref->{'ext_obj'} && ref $arg_ref->{'ext_obj'} ? $arg_ref->{'ext_obj'} : undef;
        if(!defined $ext_obj{ $ident }) {
            require CGI;
            $ext_obj{ $ident } = CGI->new();
        }
        
        $param_handler{ $ident }             = exists $arg_ref->{param_handler}           
            ? exists $arg_ref->{param_handler} : sub { $ext_obj{ $ident }->param(@_);};
        $sets_in_rows{ $ident }              = exists $arg_ref->{sets_in_rows}            ? $arg_ref->{sets_in_rows}            : 0;

        #### $self->set_result_display_map( $result_display_map{ $ident } ); # this poofs the whole thing w/out error, why ?? ##
        $self->set_page_result_display_map( $page_result_display_map{ $ident } );
        $self->set_set_result_display_map( $set_result_display_map{ $ident } );
        $self->set_html_line_white_space( $html_line_white_space{ $ident } );
        $self->set_param_handler( $param_handler{ $ident } );
        $self->set_sets_in_rows( $sets_in_rows{ $ident } );

        $total_entries{ $ident }             = exists $arg_ref->{total_entries}             ? $arg_ref->{total_entries}             
                                                                                            : $param_handler{ $ident }->($total_entries_param{ $ident }) || 100; 
        $entries_per_page{ $ident }          = exists $arg_ref->{entries_per_page}          ? $arg_ref->{entries_per_page}          
                                                                                            : 10; # param 'pp' ???
        $pages_per_set{ $ident }             = exists $arg_ref->{pages_per_set}             ? $arg_ref->{pages_per_set} : 10;
        $sets_per_set{ $ident }              = exists $arg_ref->{sets_per_set}              ? $arg_ref->{sets_per_set}  : $pages_per_set{ $ident };
        
        $page_param{ $ident }                = exists $arg_ref->{page_param}                ? $arg_ref->{page_param}    : 'pg';
        $set_param{ $ident }                 = exists $arg_ref->{set_param}                 ? $arg_ref->{set_param}     : 'st';
        $total_entries_verify_param_name{ $ident }  = exists $arg_ref->{total_entries_verify_param_name}  ? $arg_ref->{total_entries_verify_param_name}  : 've';
        $total_entries_verify_param_value{ $ident } = exists $arg_ref->{total_entries_verify_param_value} ? $arg_ref->{total_entries_verify_param_value} : '';
        
        $current_page{ $ident } = 1;
        if(!defined $arg_ref->{current_page} || $arg_ref->{current_page} !~ m/^\d+$/ 
           || $arg_ref->{current_page} < 1) {
            my $curpg = $param_handler{ $ident }->($page_param{ $ident });
            $current_page{ $ident } = $curpg if defined $curpg 
                                                && $curpg =~ m/^\d+$/ 
                                                && $curpg > 0;
        } 

        if(!defined $arg_ref->{current_set} || $arg_ref->{current_set} !~ m/^\d+$/ 
           || $arg_ref->{current_set} < 1) {
            my $curst = $param_handler{ $ident }->($set_param{ $ident });
            $current_set{ $ident } = $curst if defined $curst
                                                && $curst =~ m/^\d+$/
                                                && $curst > 0;
        }
#        $current_page{ $ident }              = exists $arg_ref->{current_page}              ? $arg_ref->{current_page}              
#                                                                                            : $param_handler{ $ident }->($page_param{ $ident }) || 1;
#        $current_set{ $ident }               = exists $arg_ref->{current_set}               ? $arg_ref->{current_set}
#                                                                                            : $param_handler{ $ident }->($set_param{ $ident }) || 1;

        $variable_entries_per_page{ $ident } = exists $arg_ref->{variable_entries_per_page} ? $arg_ref->{variable_entries_per_page} : {};

        #### second true arg is undocumented for a reason, don't use it - ever ##
        $self->set_total_entries( $total_entries{ $ident }, 1 );
        $self->set_entries_per_page( $entries_per_page{ $ident }, 1 );
        $self->set_pages_per_set( $pages_per_set{ $ident }, 1 );
        $self->set_sets_per_set( $sets_per_set{ $ident }, 1 );
        $self->_set_current_page( $current_page{ $ident }, 1 );
        $self->set_variable_entries_per_page( $variable_entries_per_page{ $ident }, 1 );

        # set up defaults...
        $data_html_config{ $ident } = {
            'col_alt_ar'    => ['data_col'],
            'row_alt_ar'    => [qw(data_light data_medium data_dark)],
            'top'           => sub {
                my ($self, $indent) = @_;
                my $ident = ident $self;
                my $start = qq($indent<table class="data_table">\n);
                return $start if !$data_html_config{ $ident }->{'inc_perpage'};
                my $colspan = exists $data_html_config{ $ident }->{'items_per_row'} && int($data_html_config{ $ident }->{'items_per_row'}) ? int($data_html_config{ $ident }->{'items_per_row'}) : 2;
                $colspan = ($colspan * 2);
                return qq($start$indent$indent<tr class="data_perpage">\n$indent$indent$indent<td colspan="$colspan">) . $self->get_perpage_html() . qq(</td>\n$indent$indent</tr>\n);
            },
            'bot'           => sub {
                my ($self, $indent) = @_;
                my $ident = ident $self;
                my $start = qq($indent</table>\n); 
                return $start if !$data_html_config{ $ident }->{'inc_perpage'};
                my $colspan = exists $data_html_config{ $ident }->{'items_per_row'} && int($data_html_config{ $ident }->{'items_per_row'}) ? int($data_html_config{ $ident }->{'items_per_row'}) : 2;
                $colspan = ($colspan * 2);
                return qq($indent$indent<tr class="data_perpage">\n$indent$indent$indent<td colspan="$colspan">) . $self->get_perpage_html() . qq(</td>\n$indent$indent</tr>\n$start);
            },
            'header'        => sub {
                my ($self, $indent) = @_;
                my $ident = ident $self;
                return '' if $data_html_config{ ident $self }->{'stop_headers'};
                my $colspan = exists $data_html_config{ $ident }->{'items_per_row'} && int($data_html_config{ $ident }->{'items_per_row'}) ? int($data_html_config{ $ident }->{'items_per_row'}) : 2;
                $colspan = ($colspan * 2);
                return qq($indent$indent<tr class="data_header">\n$indent$indent$indent<td colspan="$colspan">Setup Mode: Header, 'header' key needs set</td>\n$indent$indent</tr>\n);
            },
            'inc_perpage'   => 0,
            'start_header'  => 1,
            'items_per_row' => 1, 
            'headers_every' => 10,
            'stop_headers'  => 0,
            'restart_row_alt_on_header' => 1,  
            'start_array_index_at_zero' => 0,       
            'idx_handler'   => sub {
                my ($self, $indent, $array_idx, $col_alt) = @_;
                # $array_idx = 'undef' if !defined $array_idx;
                if(!defined $array_idx) {
                    $data_html_config{ ident $self }->{'stop_headers'} = 1;
                    return '<td class="data_na" colspan="2">Setup mode empty filler</td>';
                }
                return qq($indent$indent$indent<td class="$col_alt">Setup Mode: idx_handler array index: $array_idx</td><td class="$col_alt">'idx_handler' key needs set</td>\n);
            },
            'prerow'        => sub {
                my ($self, $indent, $row_alt) = @_; 
                return qq($indent$indent<tr class="$row_alt">\n);
            },
            'pstrow'        => sub {
                my ($self, $indent, $row_alt) = @_;
                return qq($indent$indent</tr>\n);
            },
            'no_results'    => 'Sorry, no entries were found.',
        };

        # ...change any that were passed
        $self->set_data_html_config( $arg_ref->{'data_html_config'} ) 
            if ref $arg_ref->{'data_html_config'} eq 'HASH';
        
        # ditto 
        $perpage_html_config{ $ident } = {
            'allowed'    => {},
            'all_string' => 'All',
            'pp_string'  => 'Per Page: ',
            'pp_param'   => 'pp',
        };

        $self->set_perpage_html_config( $arg_ref->{'perpage_html_config'}, 1 ) 
            if ref $arg_ref->{'perpage_html_config'} eq 'HASH';
  
        $self->_calculate();
    }

    sub set_perpage_html_config {
        my($self, $hashref, $trustme_nocalc) = @_;
        my $pp = '';
    
        for my $key (keys %{ $perpage_html_config{ ident $self } }) {
            next if !exists $hashref->{$key};
            if(ref $perpage_html_config{ ident $self }->{$key} && ref $perpage_html_config{ ident $self }->{$key} ne ref $hashref->{$key}) {
                my $ref = ref $perpage_html_config{ ident $self }->{$key};
                $ref = $ref eq 'ARRAY' ? "an $ref" : "a $ref";
                carp "$key must be $ref reference";
            }
#            elsif( ( $key eq 'foo' || $key eq 'bar') && ($hashref->{$key} !~ m{^\d+$} || $hashref->{$key} <= 0) ) {
#                carp "$key must be numeric and greater then zero";
#            }
            else {
                $perpage_html_config{ ident $self }->{$key} = $hashref->{$key};
            }
        }
        
        if( keys %{ $perpage_html_config{ ident $self }->{'allowed'} }) {
            my $test = $param_handler{ ident $self }->( $perpage_html_config{ ident $self }->{'pp_param'} );
            $pp = $test || '';
            $pp = '' if !$pp || !exists $perpage_html_config{ ident $self }->{'allowed'}{$test};
            if(exists $perpage_html_config{ ident $self }->{'allowed'}{'0'} && $pp eq '' && $test eq '0') {
                $pp = $total_entries{ ident $self };
                $perpage_html_config{ ident $self }->{'is_all'} = 1
            }
            else {
                $perpage_html_config{ ident $self }->{'is_all'} = 0;
            }
        }

        if($pp) {
            if($trustme_nocalc) {
                $entries_per_page{ ident $self } = $pp;
            }
            else {
                $self->set_entries_per_page( $pp );
            }
        }
        
        return 1;
    }
    
    sub set_data_html_config {
        my($self, $hashref) = @_;

        for my $key (keys %{ $data_html_config{ ident $self } }) {
            next if !exists $hashref->{$key};
            if(ref $data_html_config{ ident $self }->{$key} && ref $data_html_config{ ident $self }->{$key} ne ref $hashref->{$key}) {
                my $ref = ref $data_html_config{ ident $self }->{$key};
                $ref .= $ref eq 'ARRAY' ? "an $ref" : "a $ref";
                carp "$key must be $ref reference";
            }
            elsif( ( $key eq 'items_per_row' || $key eq 'headers_every') && ($hashref->{$key} !~ m{^\d+$} || $hashref->{$key} <= 0) ) {
                carp "$key must be numeric and greater then zero";
            }
            else {
                $data_html_config{ ident $self }->{$key} = $hashref->{$key};
            }
        }    
        return 1;
    }
    
    sub get_navi_html {
        my($self, $nostyle) = @_;
        my $ident = ident $self;

        my $fixq = sub {
            $ext_obj{ ident $self }->delete($page_param{ $ident }) if defined $page_param{ $ident };
            $ext_obj{ ident $self }->delete($set_param{ $ident }) if defined $page_param{ $ident };
            $ext_obj{ ident $self }->delete($total_entries_param{ $ident }) if defined $total_entries_param{ $ident };
            $ext_obj{ ident $self }->param($total_entries_param{ $ident }, $total_entries{ $ident })
                if $total_entries_param{ $ident };
            $ext_obj{ ident $self }->param($total_entries_verify_param_name{ $ident }, $total_entries_verify_param_value{ $ident })                
                if $total_entries_verify_param_value{ $ident };
            1;
        };

        $fixq->(); # do it here to clear current data

        $page_param{ $ident } = 'pg' if !$page_param{ $ident };
        $set_param{ $ident }  = 'st' if !$set_param{ $ident };

#   my $pgn = shift;
#   my $hsh = shift;
#   if(ref($hsh) eq 'HASH') { for(keys %{ $hsh }) { $var->($_,$hsh->{$_}); } }
#   $fixq->(); # do it again here in case they changed the param names on us

        my $slf  = $ext_obj{ ident $self }->url(relative=>1);
        my $sets = '';
        my $page = '';

        my $ws   = ' ' x $html_line_white_space{ $ident };

        my $div  = $as_table{ $ident } ? 'tr'  : 'div';
        my $spn  = $as_table{ $ident } ? 'td'  : 'span';
        my $tbl  = $as_table{ $ident } ? $ws   : '';
        my $beg  = $as_table{ $ident } ? "$ws<table $as_table{ $ident }>\n" : "\n";
        my $end  = $as_table{ $ident } ? "$ws</table>\n" : '';
        
# TODO-0 as_table if num of pages_in_set != $ numeber of sets (add more <td></td> or only show pages_in_set amount???)
# TODO1 if($sets_in_rows{ $ident } && $pages_per_set{ $ident }) {
#
# TODO1 } else {
            my ($simple_prev,$simple_next) = ('','');
            if($pages_per_set{ $ident }) {
                if($one_set_hide{ $ident } && $last_set{ $ident } == 1) { $sets = $one_set_html{ $ident }; }
                else {
                    $sets .= "$ws$tbl<$div class=\"$cssid_set{ $ident }\">\n";
                    $sets .= "$ws$tbl$ws<$spn class=\"cssid_set\">$of_set_html{ $ident }</$spn>\n" if $use_of_vars{ $ident };
                    $simple_prev .= qq($ws$tbl$ws<$spn class="$cssid_not_current_set{ $ident }">$no_prev_set_html{ $ident }</$spn>\n) if !$previous_set{ $ident };
                    if($previous_set{ $ident }) {
                        $ext_obj{ ident $self }->param($set_param{ $ident }, $previous_set{ $ident });
                        my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                        $ext_obj{ ident $self }->delete($set_param{ $ident });
                        $simple_prev .= qq($ws$tbl$ws<$spn class="$cssid_not_current_set{ $ident }"><a href="$url">$prev_set_html{ $ident }</a></$spn>\n);
                    }
                    $sets .= $simple_prev;

                    my $strt = $first_set_in_set{ $ident } || $first_set{ $ident };
                    my $last = $last_set_in_set{ $ident } < $last_set{ $ident } && $last_set_in_set{ $ident } > 0 ? $last_set_in_set{ $ident } : $last_set{ $ident };
                    # my $strt = $first_set{ $ident };
                    # my $last = $last_set{ $ident };

                    for($strt .. $last) {
                        $ext_obj{ ident $self }->param($set_param{ $ident }, $_);
                        my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                        $ext_obj{ ident $self }->delete($set_param{ $ident });

                        my $disp = $set_result_display_map{ $ident }->{$_} || $_;
                        $sets .= qq($ws$tbl$ws<$spn class="$cssid_current_set{ $ident }">$pre_current_set{ $ident }$disp$pst_current_set{ $ident }</$spn>\n) if $_ == $current_set{ $ident };
                        $sets .= qq($ws$tbl$ws<$spn class="$cssid_not_current_set{ $ident }">$pre_not_current_set{ $ident }<a href="$url">$disp</a>$pst_not_current_set{ $ident }</$spn>\n) if $_ != $current_set{ $ident };
                    }
                    $simple_next .= qq($ws$tbl$ws<$spn class="$cssid_not_current_set{ $ident }">$no_next_set_html{ $ident }</$spn>\n) if !$next_set{ $ident };
                    if($next_set{ $ident }) {
                        $ext_obj{ ident $self }->param($set_param{ $ident }, $next_set{ $ident });
                        my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                        $ext_obj{ ident $self }->delete($set_param{ $ident });
                        $simple_next .= qq($ws$tbl$ws<$spn class="$cssid_not_current_set{ $ident }"><a href="$url">$next_set_html{ $ident }</a></$spn>\n);
                    }
                    $sets .= $simple_next;
                    $sets .= "$ws$tbl</$div>\n";
                }
            }
            if($one_page_hide{ $ident } && $last_page{ $ident } == 1) { $page = $one_page_html{ $ident }; }
            else {
                $page .= "$ws$tbl<$div class=\"$cssid_page{ $ident }\">\n";
                $page .= "$ws$tbl$ws<$spn class=\"cssid_page\">$of_page_html{ $ident }</$spn>\n" if $use_of_vars{ $ident };
                $page .= $simple_prev if $simple_nav{ $ident };
# todo: uninitialized value [???]:
                $page .= qq($ws$tbl$ws<$spn class="$cssid_not_current_page{ $ident }">$no_prev_page_html{ $ident }</$spn>\n) if !$previous_page{ $ident };
                if($previous_page{ $ident  }) {
                    $ext_obj{ ident $self }->param($page_param{ $ident }, $previous_page{ $ident });
                    my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                    $ext_obj{ ident $self }->delete($page_param{ $ident });
                    $page .= qq($ws$tbl$ws<$spn class="$cssid_not_current_page{ $ident }"><a href="$url">$prev_page_html{ $ident }</a></$spn>\n);
                }
                my $strt = $first_page_in_set{ $ident } || $first_page{ $ident };
                my $stop = $last_page_in_set{ $ident } < $last_page{ $ident } && $last_page_in_set{ $ident } > 0 ? $last_page_in_set{ $ident } : $last_page{ $ident };
                for($strt .. $stop) {
                    $ext_obj{ ident $self }->param($page_param{ $ident }, $_);
                    my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                    $ext_obj{ ident $self }->delete($page_param{ $ident });

                    my $disp = $page_result_display_map{ $ident }->{$_} || $_;
                    $page .= qq($ws$tbl$ws<$spn class="$cssid_current_page{ $ident }">$pre_current_page{ $ident }$disp$pst_current_page{ $ident }</$spn>\n) if $_ == $current_page{ $ident };
                    $page .= qq($ws$tbl$ws<$spn class="$cssid_not_current_page{ $ident }">$pre_not_current_page{ $ident }<a href="$url">$disp</a>$pst_not_current_page{ $ident }</$spn>\n) if $_ != $current_page{ $ident };
                }
                $page .= qq($ws$tbl$ws<$spn class="$cssid_not_current_page{ $ident }">$no_next_page_html{ $ident }</$spn>\n) if !$next_page{ $ident };
                if($next_page{ $ident }) {
                    $ext_obj{ ident $self }->param($page_param{ $ident }, $next_page{ $ident });
                    my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                    $ext_obj{ ident $self }->delete($page_param{ $ident });
                    $page .= qq($ws$tbl$ws<$spn class="$cssid_not_current_page{ $ident }"><a href="$url">$next_page_html{ $ident }</a></$spn>\n);
                }
                $page .= $simple_next if $simple_nav{ $ident };
                $page .= "$ws$tbl</$div>\n";
            }
# TODO1 }
        local $style{ $ident } = '' if $nostyle;
        return "$ws$style{ $ident }$beg$page$end" if $simple_nav{ $ident };
# todo: uninitialized value [???]:
        return wantarray ? ( "$ws$style{ $ident }$beg$page$end", "$ws$style{ $ident }$beg$sets$end" ) : "$ws$style{ $ident }$beg$page$end$beg$sets$end";
    }

    sub get_data_html {
        my($self, $myconf) = @_;
        
        my $orig = $self->get_data_html_config();

        $self->set_data_html_config( $myconf ) if(defined $myconf && ref $myconf eq 'HASH');
        
        my $conf = $self->get_data_html_config();

        my $ws   = ' ' x $html_line_white_space{ ident $self };

        require List::Cycle;
        my $col_alt = List::Cycle->new({ 'values' =>  $conf->{'col_alt_ar'} });
        my $row_alt = List::Cycle->new({ 'values' =>  $conf->{'row_alt_ar'} });
        
        my $cols = int $conf->{'items_per_row'} ? int $conf->{'items_per_row'} : 1;
        my $rows = POSIX::ceil( $entries_per_page{ ident $self } / $cols );
        
        my $startit = $conf->{'start_array_index_at_zero'} ? 0 : $self->get_first() - 1;
        my $current = $startit + $cols;
        
        my $return = '';
        my $print  = defined wantarray ? sub { $return .= $_ for @_; } : sub { print @_; };

        $print->( $conf->{'top'}->($self, $ws) );
        # $print->( $conf->{'header'}->($self, $ws) ) if $conf->{'start_header'};
    
        ROW:
        for my $cur_row (0 .. ($rows - 1)) { 
            if( !($cur_row % $conf->{'headers_every'}) ) {
                $print->( $conf->{'header'}->($self, $ws) ) 
                    if !(!$conf->{'start_header'} && $cur_row == 0);
                $row_alt->reset() if $conf->{'restart_row_alt_on_header'};
            }
            last ROW if $startit >= $total_entries{ ident $self };

            my  $no_more_rows = 0;
            my $rowalt = $row_alt->next();
            $print->( $conf->{'prerow'}->( $self, $ws, $rowalt ) );
            for my $ar_idx ($startit .. ($current - 1)) {
                $ar_idx = undef if $ar_idx >= $total_entries{ ident $self };
                $no_more_rows++ if !defined $ar_idx;
                $print->( $conf->{'idx_handler'}->( $self, $ws, $ar_idx, $col_alt->next() ) );      
            }
            $print->( $conf->{'pstrow'}->( $self, $ws, $rowalt ) );
            last ROW if $no_more_rows; 
            $startit += $cols;
            $current += $cols; 
        }
        
        $print->( $conf->{'bot'}->($self, $ws) );

        $self->set_data_html_config($orig) if(defined $myconf && ref $myconf eq 'HASH');
      
        return $return if $return;
    }
    
    sub get_navi_data_navi {
        my ($self, $join) = @_;
        $join ||= "<br />\n";
        return join($join, scalar $self->get_navi_html(), $self->get_data_html(), scalar $self->get_navi_html(1));
    }
    
    sub get_perpage_html {
        my ($self, $asopts) = @_;
        my $ident = ident $self;

        my $ws = ' ' x $html_line_white_space{ $ident };
        my $html = $asopts ? qq($ws$ws<select name="$perpage_html_config{ $ident }->{'pp_param'}">\n$ws$ws$ws<option value="">$perpage_html_config{ $ident }->{'pp_string'}</option>\n)
                           : '';
                           
        my $pp_value = $ext_obj{ ident $self }->param( $perpage_html_config{ $ident }->{'pp_param'} );
        if ( !exists $perpage_html_config{ $ident }->{'allowed'}{ $pp_value } ) { 
            $ext_obj{ ident $self }->param( $perpage_html_config{ $ident }->{'pp_param'}, $entries_per_page{ ident $self });
            $pp_value = $entries_per_page{ ident $self };
        }

        $ext_obj{ ident $self }->param($total_entries_verify_param_name{ $ident }, $total_entries_verify_param_value{ $ident })                
            if $total_entries_verify_param_value{ $ident };
            
        my $slf = $ext_obj{ ident $self }->url(relative=>1);

        if(keys %{ $perpage_html_config{ $ident }->{'allowed'} }) {
            for my $num ( sort { $a <=> $b } grep { $_ > 0 } keys %{ $perpage_html_config{ $ident }->{'allowed'} }) {
                if($num == $entries_per_page{ ident $self }) {
                    $html .= $asopts ? qq($ws$ws$ws<option value="$num" selected>$num</option>\n)
                                     : qq($pre_current_page{ ident $self }$num$pst_current_page{ ident $self } );
                }
                else {
                    if(!$asopts) {
                        $ext_obj{ ident $self }->param($perpage_html_config{ $ident }->{'pp_param'}, $num);
                        my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                        $html .= qq($pre_not_current_page{ ident $self }<a href="$url">$num</a>$pst_not_current_page{ ident $self } ); 
                        $ext_obj{ ident $self }->param( $perpage_html_config{ $ident }->{'pp_param'}, $pp_value );
                    }
                    else {
                        $html .= qq($ws$ws$ws<option value="$num" >$num</option>\n)
                    }
                }
            }
      
            if(exists $perpage_html_config{ $ident }->{'allowed'}{'0'}) {
                if($entries_per_page{ ident $self } == $total_entries{ ident $self } && $perpage_html_config{ $ident }->{'is_all'}) {
                    $html .= $asopts ? qq($ws$ws$ws<option value="0" selected>$perpage_html_config{ $ident }->{'all_string'}</option>\n)
                                     : qq($pre_current_page{ ident $self }$perpage_html_config{ $ident }->{'all_string'}$pst_current_page{ ident $self } );
                }
                else {
                    if(!$asopts) {
                        $ext_obj{ ident $self }->param($perpage_html_config{ $ident }->{'pp_param'}, 0);
                        my $url = $slf . '?' . $ext_obj{ ident $self }->query_string();
                        $html .= qq($pre_not_current_page{ ident $self }<a href="$url">$perpage_html_config{ $ident }->{'all_string'}</a>$pst_not_current_page{ ident $self } );
                        $ext_obj{ ident $self }->param( $perpage_html_config{ $ident }->{'pp_param'}, $pp_value );
                    }
                    else {
                        $html .= qq($ws$ws$ws<option value="0" >$perpage_html_config{ $ident }->{'all_string'}</option>\n);
                    }
                }
            }
        }
 
        if(!$asopts) {
            $html =~ s{ $}{};
            $html = $perpage_html_config{ $ident }->{'pp_string'} . $html if $html;
        }
        else {
            $html .= "$ws$ws</select>\n";
        }

        return $html;
    }
    
    sub get_perpage_html_select {
        shift->get_perpage_html(1); 
    }
    
    sub _default_style {
        my($self) = @_;
        my $ws = ' ' x $html_line_white_space{ ident $self };
        return <<"END_CSS";
$ws<style type="text/css">
$ws<!-- 

$ws$ws.page {
$ws$ws${ws}text-align: center;
$ws$ws} 

$ws$ws.set {
$ws$ws${ws}text-align: center;
$ws$ws}

$ws$ws.data_table {
$ws$ws${ws}margin-left:auto; 
$ws$ws${ws}margin-right:auto;
$ws$ws${ws}color: #202020;
$ws$ws${ws}border: solid #202020 1px;
$ws$ws${ws}/* border-collapse: collapse; */
$ws$ws${ws}border-spacing: 1px;
$ws$ws}

$ws$ws.data_header {
$ws$ws${ws}text-align: center;
$ws$ws${ws}background-color: #787878;
$ws$ws${ws}color: #F8F8F8;
$ws$ws${ws}font-weight: bold;
$ws$ws}

$ws$ws.data_perpage {
$ws$ws${ws}text-align: right;
$ws$ws}

$ws$ws.data_na {
$ws$ws${ws}background-color: #F5F5F5; 
$ws$ws${ws}color: #DCDCDC;
$ws$ws}

$ws$ws.data_light {
$ws$ws${ws}background-color: #F0F0F0;
$ws$ws}

$ws$ws.data_medium {
$ws$ws${ws}background-color: #D8D8D8;
$ws$ws}

$ws$ws.data_dark {
$ws$ws${ws}background-color: #C0C0C0;
$ws$ws}

$ws-->
$ws</style>
END_CSS
    }

} #### end scoping "inside-out" class ##

1;

__END__

=head1 NAME

Data::Paginate - Perl extension for complete and efficient data pagination

=head1 SYNOPSIS

   use Data::Paginate;
   my $pgr = Data::Paginate->new(\%settings);

=head1 DESCRIPTION

This module gives you a single resource to paginate data very simply. 

It includes access to the page/data variables as well as a way to generate the navigation HTML and get the data for the current page from a list of data and many many other things. It can definately be extended to generate the navigation cotrols for XML, Tk, Flash, Curses, etc... (See "SUBCLASSING" below)

Each item in the "new()" and "Non new() entries" sections have a get_ and set_ method unless otherwise specified.

By that I mean if the "item" is "foo" then you can set it with $pgr->set_foo($new_value) and get it with $pgr->get_foo()...

=head1 new()

Its only argument can be a hashref where its keys are the names documented below in sections that say it can be specified in new().

Also, total_entries is the item that makes the most sense to use if you're only using one :)

=head2 Attributes that recalculate the page dynamics 

These all have get_ and set_ methods and can be specified in the hashref to new()

=over

=item total_entries (100)

This is the number of pieces of data to paginate.

When set it can be a digit or an array reference (whose number of elements is used as the digit)

=item entries_per_page (10)

The number of the "total_entries" that go in each page.

=item pages_per_set (10)

If set to a digit greater than 0 it turns on the use of "sets" in the object and tells it how many pages are to be in each set.

This is very handy to make the navigation easier to use. Say you have data that is paginated to 1000 pages.

If you set this to, say 20, you'd see navigation for pages 1..20, then 21..30, etc etc instead of 1..1000 which would be ungainly.

The use of sets is encouraged but you can turn it off by setting it to 0.

=item sets_per_set (pages_per_set)

If sets are in use then this is how many sets to show in the navigation. 
So if there are 100 sets and its set to 10 it will show 11-20 if you are on say set 12.

=item current_page (1)

The current page of the data set. 

No set_ method. (IE it needs to be specified in new() or via the param handler (which is also set in new()) 

=item variable_entries_per_page ({})

An optional hashref whose key is the page number and the value is the number of entries for that page. 

For example to make all your data paginated as a haiku:

   $pgr->set_variable_entries_per_page({
       '1' => '5',
       '2' => '7',
       '3' => '5',
   });

Page 1 will have 5 records, page 2 will have 7 records, and page 3 will have 5 records.

Pages 4 on will have "entries_per_page" records.

It is ok to not specify them in any sort of range or run:

   $pgr->set_variable_entries_per_page({
       '34' => '42',
       '55' => '78',
       '89' => '99',
   });

=back

=head2 Some display settings that require specific types of values.

These all have get_ and set_ methods and can be specified in the hashref to new().

Their argument in assignments must be the same type as the default values.

=over

=item page_result_display_map ({})

An optional hashref whose key is the page number and the value is what to use in the navigation instead of the digit.

=item set_result_display_map ({})

An optional hashref whose key is the set number and the value is what to use in the navigation instead of the digit.

=item result_display_map ({})

An optional hashref that sets page_result_display_map and set_result_display_map to the same thing.

There is no get_ method for this.

=item html_line_white_space (0)

A digit that specifies the number of spaces to indent the HMTL in any get_*_html functions.

=item param_handler

A CODE reference to handle the parameres. See source if you have a need to modify this.

There is no get_ method for this.

=item sets_in_rows (0)

Not currently used, see TODO.

=back

=head2 Misc (HTML) display settings

All have get_ and set_ methods and can be specfied in new()

=over

=item pre_current_page (&#187;)

=item pst_current_page (&#171;)

=item pst_current_set (&#187;)

=item pre_current_set (&#171;)

=item total_entries_param (te)

=item set_param (st)

=item next_page_html (Next Page &rarr;)

=item page_param (pg)

=item simple_nav (0)

=item cssid_set (set)

=item cssid_not_current_page (notpg)

=item cssid_current_set (curst)

=item pre_not_current_set ([)

=item pre_not_current_page ([)

=item pst_not_current_set (])

=item pst_not_current_page (])

=item prev_set_html (&larr; Prev Set)

=item one_set_hide (0)

=item no_prev_set_html ('')

=item as_table (0)

=item style (style tag that centers "#page" and "#set"

=item no_prev_page_html ('')

=item one_page_hide (0)

=item next_set_html (Next Set &rarr;)

=item one_set_html ('')

=item no_next_page_html ('')

=item cssid_current_page (curpg)

=item no_next_set_html ('')

=item prev_page_html (&larr; Prev Page)

=item cssid_page (page)

=item cssid_not_current_set (notst)

=item use_of_vars (0)

=item one_page_html ('')

=item of_page_string (Page)

=item of_set_string (Set)

=item of_of_string (of)

=item of_page_html ('')

=item of_set_html ('')

=back 

=head1 Non new() entries

=head2 Data that gets set during calculation. 

Each has a get_ function but does not have a set_ funtion and cannot be specified in new()


=over

=item entries_on_this_page

The number of entries on the page, its always "entries_per_page" except when you are on the last page and there are less than "entries_per_page" left.

=item first_page 

The first page number, its always 1.

=item last_page

The last page number.

=item first

first record in page counting from 1 not 0

=item last 

last record on page counting from 1 not 0

=item previous_page 

Number of the previous page. 0 if currently on page 1

=item next_page  

Number of the next page. 0 if currently on last page.

=item current_set

Number of the current set

=item previous_set 

Number of the previous set. 0 if currently on set 1

=item next_set  

Number of the next set. 0 if currently on last set.

=item pages_in_set  

The number of pages in this set, its always "pages_per_set" except when you are on the last set and there are less than "pages_per_set" left.

=item last_set  

Number of last set.

=item first_set    

Number of first set, always 1

=item last_page_in_set    

Page number of the last page in the set.

=item first_page_in_set    

Page number of the first page in the set.

=item first_set_in_set

First set in this display's "sets_per_set" range.

=item last_set_in_set

Last set in this display's "sets_per_set" range.

=back

=head1 Other methods

=head2 $pgr->get_navi_html()

Get HTML navigation for the object's current state.

In scalar context returns a single string with the HTML navigation.

In array context returns the page HTML as the first item and the set HTML as the second.

If simple_nav is true it returns a single string regardless of context.

    print scalar $pgr->get_navi_html();

=head2 $pgr->get_data_html()

See "to do"

=head2 get_ misc data (IE no set_)                          

=over

=item get_pages_range 


Returns an array of numbers that are indexes of the current page's range on the data array.

=item get_pages_splice 
        

Returns an array of the current page's data as sliced for the given arrayref.
        
    my @data_to_display = $pgr->get_pages_slice(\@orig_data);

=item get_pages_splice_ref        

Same as get_pages_splice but returns an array ref instead of an array.
        

=item get_firstlast 
           

In array context returns $pgr->get_first() and $pgr->get_last() as its items.
In scalar context it returns a stringified, comma seperated version.
        
    my($first, $last)  = $pgr->get_firstlast(); # '1' and '10' respectively
    my $first_last_csv = $pgr->get_firstlast(); # '1,10'

=item get_lastfirst

In array context returns $pgr->get_last() and $pgr->get_first() as its items.
In scalar context it returns a stringified, comma seperated version.

    my($last, $first)  = $pgr->get_lastfirst(); # '10' and '1' respectively
    my $last_first_csv = $pgr->get_lastfirst(); # '10,1'

=item get_state_hashref

Returns a hashref that is a snapshot of the current state of the object.
Useful for debugging and development.

=back

=head1 EXAMPLE use for HTML

Example using module to not only paginate easily but optimize database calls:

    # set total_entries *once* then pass it around 
    # in the object's links from then on for efficiency:
    my ($total_entries) = CGI::param('te') =~ m/^\d+$/ && CGI::param('te') > 0
        ? CGI::param('te') 
        : $dbh->select_rowarray("SELECT COUNT(*) FROM baz WHERE $where");

    my $pgr = Data::Paginate->new({ total_entries => $total_entries });

    # only SELECT current page's records:
    # Hint: set 'data_html_config's 'start_array_index_at_zero' to true if you are using 'data_html_config'
    #   that way the array index pass to idx_handlers for the array of records for this page (IE the LIMITed records) 
    # LIMIT $pgr->get_entries_per_page() OFFSET ($pgr->get_first() - 1)
    my $query = "SELECT foo, bar FROM baz WHERE $where LIMIT ? OFFSET ?";

    print scalar $pgr->get_navi_html();

    for my $record (@{ $dbh->selectall_arrayref($query, undef, $pgr->get_entries_per_page(), ($pgr->get_first() - 1)) }) {
        # display $record here
    }

    print scalar $pgr->get_navi_html();

Example to keep the 'te' parameter safe from being spoofed (and do same optimization as above) - HIGHLY RECOMMENDED:

    my $verify        = CGI::param('ve') || '';
    my $total_entries = int( CGI::param('te') );
    my $te_match      = $total_entries ? Digest::MD5::md5_hex("unique_cypher-$total_entries-$where") : '';
    if(!$total_entries || $verify ne $te_match) {
        # its not ok so re-fetch
        ($total_entries) = $dbh->select_rowarray("SELECT COUNT(*) FROM baz WHERE $where");
        $te_match        = Digest::MD5::md5_hex("unique_cypher-$total_entries-$where");
    }
    # otherwise its all ok so use it 
    my $pgr = Data::Paginate->new({ 
        'total_entries' => $total_entries,
        'total_entries_verify_param_value' => $te_match,
    ...

=head1 SUBCLASSING

If you'd like to add functionality to this module *please* do it correctly. Part of the reason I made this module was that similar modules had functionality spread out among several modules that did not use the namespace model or subclassing paradigm correctly and made it really confusing and difficult to use.

So say you want to add functionality for TMBG please do it like so:

- use "Data::Paginate::TMBG" as the package name.

- use Data::Paginate; in your module (use base 'Data::Paginate'; for inheritence)

- make the method name like so (or prefix w/ Data::Paginate:: if !use base, but why would you do that ;p):

    sub get_navi_tmbg { # each subclass should have a get_navi_* function so its use is consistent
         my ($pgr) = @_; # Data::Paginate Object

    sub make_a_little_birdhouse_in_your_soul {
         my ($pgr) = @_; # Data::Paginate Object

That way it can be used like so:

    use Data::Paginate::TMBG; # no need to use Data::Paginate in the script since your module will use() it for use in its method(s)

    my $pgr = Data::Paginate->new({ total_entries => $total_entries }):

    $pgr->make_a_little_birdhouse_in_your_soul({ 'say' => q{I'm the only bee in your bonnet} }); # misc function to do whatever you might need

    print $pgr->get_navi_tmbg();

=head1 TO DO

- POD and Changelog for 0.0.2 and 0.0.3

  data_na CSS class
  total_entries_verify_param_name (ve)
  total_entries_verify_param_value ('')

  [set_]ext_obj
  [get|set]_data_html_config + new()
  [get|set]_perpage_html_config + new()
  get_navi_html(\$nostyle)
  get_data_html() (plus style{} addition)
  get_state_html()
  get_navi_data_navi()
  get_perpage_html()
  get_perpage_html_select() IE: get_perpage_html(1)

- Support Locale::Maketext handles for output in any language

- A few additions to get_navi_html()

- Improve POD documentation depending on feedback.

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
