package Cron::Toolkit::Tree::EnglishVisitor;
use parent 'Cron::Toolkit::Tree::Visitor';
use Cron::Toolkit::Tree::Utils qw(:all);
sub new {
    my ($class, %args) = @_;
    $args{hour} //= 0;
    return $class->SUPER::new(%args);
}
sub visit {
    my ($self, $node, @child_results) = @_;
    my $data = {
        field_type => $self->{field_type},
        node => $node,
        child_results => \@child_results,
    };
    my $ft = $data->{field_type};
    # ------------------------------------------------------------------
    # 1. Single value
    # ------------------------------------------------------------------
    if ($node->{type} eq 'single') {
        my $v = $node->{value};
        if ($ft eq 'dow') {
            $data->{day} = $day_names{$v} || $v;
            $self->{result} = fill_template('dow_single', $data);
        }
        elsif ($ft eq 'dom') {
            $data->{ordinal} = num_to_ordinal($v);
            $self->{result} = fill_template('dom_single_every', $data);
        }
        elsif ($ft eq 'year') {
            $data->{year} = $v;
            $self->{result} = fill_template('year_in', $data);
        }
        else {
            $self->{result} = $v;
        }
    } elsif ($node->{type} eq 'wildcard' || $node->{type} eq 'unspecified') {
        $self->{result} = '';
    } elsif ($node->{type} eq 'range') {
        if ($ft eq 'dom') {
            $data->{start} = num_to_ordinal($node->{children}[0]->{value});
            $data->{end} = num_to_ordinal($node->{children}[1]->{value});
            $self->{result} = fill_template('dom_range_every', $data);
        } elsif ($ft =~ /^(second|minute|hour)$/) {
            $data->{start} = $node->{children}[0]->{value};
            $data->{end} = $node->{children}[1]->{value};
            $self->{result} = fill_template("time_range_$ft", $data);
        } else {
            $self->{result} = '';
        }
    } elsif ($node->{type} eq 'step') {
        my $base_node = $node->{children}[0];
        my $step_node = $node->{children}[1];
        $data->{step} = $step_node->{value};
        if ($base_node->{type} eq 'wildcard') {
            my $tmpl = 'every_N_' . $ft;
            $self->{result} = fill_template($tmpl, $data);
        } elsif ($base_node->{type} eq 'range') {
            $data->{start} = $base_node->{children}[0]{value};
            $data->{end} = $base_node->{children}[1]{value};
            $data->{hour} = $self->{hour};
            $self->{result} = fill_template('step_range', $data);
        } elsif ($base_node->{type} eq 'single') {
            $data->{start} = $base_node->{value};
            $self->{result} = fill_template('step_single', $data);
        }
    } elsif ($node->{type} eq 'list') {
        $self->{result} = generate_list_desc($ft, $node->{children});
    } elsif ($node->{type} eq 'last') {
        $self->{result} = fill_template('dom_last', $data);
    } elsif ($node->{type} eq 'lastW') {
        $self->{result} = fill_template('dom_lw', $data);
    } elsif ($node->{type} eq 'nth') {
        my ($day, $nth) = $node->{value} =~ /(\d+)#(\d+)/;
        $data->{nth} = num_to_ordinal($nth);
        $data->{day} = $day_names{$day};
        $self->{result} = fill_template('dow_nth', $data);
    } elsif ($node->{type} eq 'nearest_weekday') {
        my ($day) = $node->{value} =~ /(\d+)W/;
        $data->{ordinal} = num_to_ordinal($day);
        $self->{result} = fill_template('dom_nearest_weekday', $data);
    } else {
        $self->{result} = '';
    }
    return $self->{result};
}
1;
