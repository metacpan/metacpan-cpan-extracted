package Algorithm::LibLinear::Types;

use 5.014;
use Mouse::Util::TypeConstraints;

subtype 'Algorithm::LibLinear::Feature'
    => as 'HashRef[Num]'
    => where {
        for my $index (keys %$_) {
            return unless $index == int $index and $index > 0;
        }
        return 1;
    };

subtype 'Algorithm::LibLinear::LabeledData'
    => as 'HashRef'
    => where {
        return if keys %$_ != 2;
        for my $key (qw/feature label/) { return unless exists $_->{$key} }
        state $label_type = find_type_constraint 'Num';
        state $feature_type =
            find_type_constraint 'Algorithm::LibLinear::Feature';
        $label_type->check($_->{label}) and $feature_type->check($_->{feature});
    };

subtype 'Algorithm::LibLinear::TrainingParameter::ClassWeight'
    => as 'HashRef'
    => where {
        return if keys %$_ != 2;
        for my $key (qw/label weight/) { return unless exists $_->{$key} }
        state $label_type = find_type_constraint 'Int';
        state $weight_type = find_type_constraint 'Num';
        $label_type->check($_->{label}) and $weight_type->check($_->{weight});
    };

enum 'Algorithm::LibLinear::SolverDescriptor' => [
    qw/L2R_LR L2R_L2LOSS_SVC_DUAL L2R_L2LOSS_SVC L2R_L1LOSS_SVC_DUAL MCSVM_CS
       L1R_L2LOSS_SVC L1R_LR L2R_LR_DUAL L2R_L2LOSS_SVR L2R_L2LOSS_SVR_DUAL
       L2R_L1LOSS_SVR_DUAL/
];

no Mouse::Util::TypeConstraints;

1;
