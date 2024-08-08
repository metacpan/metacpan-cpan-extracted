package CVSS::Constants;

use feature ':5.10';
use strict;
use utf8;
use warnings;

our $VERSION = '1.12';
$VERSION =~ tr/_//d;    ## no critic


# CVSS v2.0 constants

use constant CVSS2_SCORE_SEVERITY => {
    NONE   => {min => 0.0, max => 0.0},
    LOW    => {min => 0.1, max => 3.9},
    MEDIUM => {min => 4.0, max => 6.9},
    HIGH   => {min => 7.0, max => 10.0},
};

use constant CVSS2_NOT_DEFINED_VALUE => 'ND';

use constant CVSS2_VECTOR_STRING_REGEX =>
    qr{^((AV:[NAL]|AC:[LMH]|Au:[MSN]|[CIA]:[NPC]|E:(U|POC|F|H|ND)|RL:(OF|TF|W|U|ND)|RC:(UC|UR|C|ND)|CDP:(N|L|LM|MH|H|ND)|TD:(N|L|M|H|ND)|[CIA]R:(L|M|H|ND))/)*(AV:[NAL]|AC:[LMH]|Au:[MSN]|[CIA]:[NPC]|E:(U|POC|F|H|ND)|RL:(OF|TF|W|U|ND)|RC:(UC|UR|C|ND)|CDP:(N|L|LM|MH|H|ND)|TD:(N|L|M|H|ND)|[CIA]R:(L|M|H|ND))$};


use constant CVSS2_METRIC_GROUPS =>
    {base => [qw(AV AC Au C I A)], temporal => [qw(E RL RC)], environmental => [qw(CDP TD CR IR AR)]};

use constant CVSS2_WEIGHTS => {

    AV => {N => 1.0,  A => 0.646, L => 0.395},
    AC => {H => 0.35, M => 0.61,  L => 0.71},
    Au => {M => 0.45, S => 0.56,  N => 0.704},
    C  => {N => 0.0,  P => 0.275, C => 0.660},
    I  => {N => 0.0,  P => 0.275, C => 0.660},
    A  => {N => 0.0,  P => 0.275, C => 0.660},

    E  => {U  => 0.85, POC => 0.9,  F => 0.95, H  => 1.00, ND => 1.00},
    RL => {OF => 0.87, TF  => 0.90, W => 0.95, U  => 1.00, ND => 1.00},
    RC => {UC => 0.90, UR  => 0.95, C => 1.00, ND => 1.00},

    CDP => {N => 0,   L => 0.1,  LM => 0.3,  MH => 0.4, H  => 0.5, ND => 0},
    TD  => {N => 0,   L => 0.25, M  => 0.75, H  => 1.0, ND => 1.0},
    CR  => {L => 0.5, M => 1.0,  H  => 1.51, ND => 1.0},
    IR  => {L => 0.5, M => 1.0,  H  => 1.51, ND => 1.0},
    AR  => {L => 0.5, M => 1.0,  H  => 1.51, ND => 1.0},

};

use constant CVSS2_ATTRIBUTES => {

    # Base metrics
    accessVector          => 'AV',
    accessComplexity      => 'AC',
    authentication        => 'Au',
    confidentialityImpact => 'C',
    integrityImpact       => 'I',
    availabilityImpact    => 'A',

    # Temporal
    exploitability   => 'E',
    remediationLevel => 'RL',
    reportConfidence => 'RC',

    # Environmental
    collateralDamagePotential  => 'CDP',
    targetDistribution         => 'TD',
    confidentialityRequirement => 'CR',
    integrityRequirement       => 'IR',
    availabilityRequirement    => 'AR',

};

use constant CVSS2_METRIC_VALUES => {

    AV => [qw(N A L)],
    AC => [qw(H M L)],
    Au => [qw(M S N)],
    C  => [qw(N P C)],
    I  => [qw(N P C)],
    A  => [qw(N P C)],

    E  => [qw(U POC F H ND)],
    RL => [qw(OF TF W U ND)],
    RC => [qw(UC UR C ND)],

    CDP => [qw(N L LM MH H ND)],
    TD  => [qw(N L M H ND)],
    CR  => [qw(L M H ND)],
    IR  => [qw(L M H ND)],
    AR  => [qw(L M H ND)],

};

sub CVSS2_METRIC_NAMES {

    my $ND = 'NOT_DEFINED';

    my $AV = {N => 'NETWORK',  A => 'ADJACENT_NETWORK', L => 'LOCAL'};
    my $AC = {H => 'HIGH',     M => 'MEDIUM',           L => 'LOW'};
    my $Au = {M => 'MULTIPLE', S => 'SINGLE',           N => 'NONE'};
    my $C  = {N => 'NONE',     P => 'PARTIAL',          C => 'COMPLETE'};
    my $I  = {N => 'NONE',     P => 'PARTIAL',          C => 'COMPLETE'};
    my $A  = {N => 'NONE',     P => 'PARTIAL',          C => 'COMPLETE'};

    my $E  = {U  => 'UNPROVEN',     POC => 'PROOF_OF_CONCEPT', F => 'FUNCTIONAL', H  => 'HIGH',        ND => $ND};
    my $RL = {OF => 'OFFICIAL_FIX', TF  => 'TEMPORARY_FIX',    W => 'WORKAROUND', U  => 'UNAVAILABLE', ND => $ND};
    my $RC = {UC => 'UNCONFIRMED',  UR  => 'UNCORROBORATED',   C => 'CONFIRMED',  ND => $ND};

    my $CDP = {N => 'NONE', L => 'LOW',    LM => 'LOW_MEDIUM', MH => 'MEDIUM_HIGH', H => 'HIGH', ND => $ND};
    my $TD  = {N => 'NONE', L => 'LOW',    M  => 'MEDIUM',     H  => 'HIGH', ND => $ND};
    my $CR  = {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => $ND};
    my $IR  = {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => $ND};
    my $AR  = {L => 'LOW',  M => 'MEDIUM', H  => 'HIGH',       ND => $ND};

    return {

        # Base
        AV => {json => 'accessVector',          values => $AV},
        AC => {json => 'accessComplexity',      values => $AC},
        Au => {json => 'authentication',        values => $Au},
        C  => {json => 'confidentialityImpact', values => $C},
        I  => {json => 'integrityImpact',       values => $I},
        A  => {json => 'availabilityImpact',    values => $A},

        # Temporal
        E  => {json => 'exploitability',   values => $E},
        RL => {json => 'remediationLevel', values => $RL},
        RC => {json => 'reportConfidence', values => $RC},

        # Environmental
        CDP => {json => 'collateralDamagePotential',  values => $CDP},
        TD  => {json => 'targetDistribution',         values => $TD},
        CR  => {json => 'confidentialityRequirement', values => $CR},
        IR  => {json => 'integrityRequirement',       values => $IR},
        AR  => {json => 'availabilityRequirement',    values => $AR},

    };
}


# CVSS v3.x constans

use constant CVSS3_SCORE_SEVERITY => {
    NONE     => {min => 0.0, max => 0.0},
    LOW      => {min => 0.1, max => 3.9},
    MEDIUM   => {min => 4.0, max => 6.9},
    HIGH     => {min => 7.0, max => 8.9},
    CRITICAL => {min => 9.0, max => 10.0}
};


use constant CVSS3_NOT_DEFINED_VALUE => 'X';

use constant CVSS3_METRIC_GROUPS => {
    base          => [qw(AV AC PR UI S C I A)],
    temporal      => [qw(E RL RC)],
    environmental => [qw(CR IR AR MAV MAC MPR MUI MS MC MI MA)],
};

use constant CVSS3_VECTOR_STRING_REGEX =>
    qr{^CVSS:3\.[0-1]\/((AV:[NALP]|AC:[LH]|PR:[UNLH]|UI:[NR]|S:[UC]|[CIA]:[NLH]|E:[XUPFH]|RL:[XOTWU]|RC:[XURC]|[CIA]R:[XLMH]|MAV:[XNALP]|MAC:[XLH]|MPR:[XUNLH]|MUI:[XNR]|MS:[XUC]|M[CIA]:[XNLH])\/)*(AV:[NALP]|AC:[LH]|PR:[UNLH]|UI:[NR]|S:[UC]|[CIA]:[NLH]|E:[XUPFH]|RL:[XOTWU]|RC:[XURC]|[CIA]R:[XLMH]|MAV:[XNALP]|MAC:[XLH]|MPR:[XUNLH]|MUI:[XNR]|MS:[XUC]|M[CIA]:[XNLH])$};

use constant CVSS3_WEIGHTS => {

    # Base

    AV => {N => 0.85, A => 0.62, L => 0.55, P => 0.2},
    AC => {H => 0.44, L => 0.77},

    # These values are used if Scope is Changed
    PR => {U => {N => 0.85, L => 0.62, H => 0.27}, C => {N => 0.85, L => 0.68, H => 0.5}},

    UI => {N => 0.85, R => 0.62},
    S  => {U => 6.42, C => 7.52},    # Note: not defined as constants in specification

    # C, I and A have the same weights
    C => {N => 0, L => 0.22, H => 0.56},
    I => {N => 0, L => 0.22, H => 0.56},
    A => {N => 0, L => 0.22, H => 0.56},

    # Temporal

    E  => {X => 1, U => 0.91, P => 0.94, F => 0.97, H => 1},
    RL => {X => 1, O => 0.95, T => 0.96, W => 0.97, U => 1},
    RC => {X => 1, U => 0.92, R => 0.96, C => 1},

    # Environmental

    # CR, IR and AR have the same weights
    CR => {X => 1, L => 0.5, M => 1, H => 1.5},
    IR => {X => 1, L => 0.5, M => 1, H => 1.5},
    AR => {X => 1, L => 0.5, M => 1, H => 1.5},

    # (modified Base)

    MAV => {N => 0.85, A => 0.62, L => 0.55, P => 0.2},
    MAC => {H => 0.44, L => 0.77},

    # These values are used if Scope is Changed
    MPR => {U => {N => 0.85, L => 0.62, H => 0.27}, C => {N => 0.85, L => 0.68, H => 0.5}},

    MUI => {N => 0.85, R => 0.62},
    MS  => {U => 6.42, C => 7.52},    # Note: not defined as constants in specification

    # C, I and A have the same weights
    MC => {N => 0, L => 0.22, H => 0.56},
    MI => {N => 0, L => 0.22, H => 0.56},
    MA => {N => 0, L => 0.22, H => 0.56},

};

use constant CVSS3_ATTRIBUTES => {

    # Base metrics
    attackVector          => 'AV',
    attackComplexity      => 'AC',
    privilegesRequired    => 'PR',
    userInteraction       => 'UI',
    scope                 => 'S',
    confidentialityImpact => 'C',
    integrityImpact       => 'I',
    availabilityImpact    => 'A',

    # Temporal metrics
    exploitCodeMaturity => 'E',
    remediationLevel    => 'RL',
    reportConfidence    => 'RC',

    # Enviromental metrics
    confidentialityRequirement    => 'CR',
    integrityRequirement          => 'IR',
    availabilityRequirement       => 'AR',
    modifiedAttackVector          => 'MAV',
    modifiedAttackComplexity      => 'MAC',
    modifiedPrivilegesRequired    => 'MPR',
    modifiedUserInteraction       => 'MUI',
    modifiedScope                 => 'MS',
    modifiedConfidentialityImpact => 'MC',
    modifiedIntegrityImpact       => 'MI',
    modifiedAvailabilityImpact    => 'MA',

};

use constant CVSS3_METRIC_VALUES => {

    AV => [qw(N A L P)],
    AC => [qw(L H)],
    PR => [qw(N L H)],
    UI => [qw(N R)],
    S  => [qw(U C)],
    C  => [qw(N L H)],
    I  => [qw(N L H)],
    A  => [qw(N L H)],

    E  => [qw(X U P F H)],
    RL => [qw(X O T W U)],
    RC => [qw(X U R C)],

    MAV => [qw(X N A L P)],
    MAC => [qw(X L H)],
    MPR => [qw(X N L H)],
    MUI => [qw(X N R)],
    MS  => [qw(X U C)],
    MC  => [qw(X N L H)],
    MI  => [qw(X N L H)],
    MA  => [qw(X N L H)],
    CR  => [qw(X L M H)],
    IR  => [qw(X L M H)],
    AR  => [qw(X L M H)],

};

sub CVSS3_METRIC_NAMES {

    my $AV = {N => 'NETWORK',   A => 'ADJACENT_NETWORK', L => 'LOCAL', P => 'PHYSICAL'};
    my $AC = {H => 'HIGH',      L => 'LOW'};
    my $PR = {N => 'NONE',      L => 'LOW', H => 'HIGH'};
    my $UI = {N => 'NONE',      R => 'REQUIRED'};
    my $S  = {U => 'UNCHANGED', C => 'CHANGED'};
    my $C  = {N => 'NONE',      L => 'LOW', H => 'HIGH'};
    my $I  = {N => 'NONE',      L => 'LOW', H => 'HIGH'};
    my $A  = {N => 'NONE',      L => 'LOW', H => 'HIGH'};

    my $E  = {X => 'NOT_DEFINED', U => 'UNPROVEN',     P => 'PROOF_OF_CONCEPT', F => 'FUNCTIONAL', H => 'HIGH'};
    my $RL = {X => 'NOT_DEFINED', O => 'OFFICIAL_FIX', T => 'TEMPORARY_FIX',    W => 'WORKAROUND', U => 'UNAVAILABLE'};
    my $RC = {X => 'NOT_DEFINED', U => 'UNKNOWN',      R => 'REASONABLE',       C => 'CONFIRMED'};

    my $CR  = {X => 'NOT_DEFINED', L => 'LOW',              M => 'MEDIUM', H => 'HIGH'};
    my $IR  = {X => 'NOT_DEFINED', L => 'LOW',              M => 'MEDIUM', H => 'HIGH'};
    my $AR  = {X => 'NOT_DEFINED', L => 'LOW',              M => 'MEDIUM', H => 'HIGH'};
    my $MAV = {N => 'NETWORK',     A => 'ADJACENT_NETWORK', L => 'LOCAL',  P => 'PHYSICAL', X => 'NOT_DEFINED'};
    my $MAC = {H => 'HIGH',        L => 'LOW',              X => 'NOT_DEFINED'};
    my $MPR = {N => 'NONE',        L => 'LOW',              H => 'HIGH', X => 'NOT_DEFINED'};
    my $MUI = {N => 'NONE',        R => 'REQUIRED',         X => 'NOT_DEFINED'};
    my $MS  = {U => 'UNCHANGED',   C => 'CHANGED',          X => 'NOT_DEFINED'};
    my $MC  = {N => 'NONE',        L => 'LOW',              H => 'HIGH', X => 'NOT_DEFINED'};
    my $MI  = {N => 'NONE',        L => 'LOW',              H => 'HIGH', X => 'NOT_DEFINED'};
    my $MA  = {N => 'NONE',        L => 'LOW',              H => 'HIGH', X => 'NOT_DEFINED'};

    my @AV = (qw[N A L P]);

    return {
        # Base
        AV => {json => 'attackVector',          values => $AV, names => {reverse(%{$AV})}},
        AC => {json => 'attackComplexity',      values => $AC, names => {reverse(%{$AC})}},
        PR => {json => 'privilegesRequired',    values => $PR, names => {reverse(%{$PR})}},
        UI => {json => 'userInteraction',       values => $UI, names => {reverse(%{$UI})}},
        S  => {json => 'scope',                 values => $S,  names => {reverse(%{$S})}},
        C  => {json => 'confidentialityImpact', values => $C,  names => {reverse(%{$C})}},
        I  => {json => 'integrityImpact',       values => $I,  names => {reverse(%{$I})}},
        A  => {json => 'availabilityImpact',    values => $A,  names => {reverse(%{$A})}},

        # Temporal
        E  => {json => 'exploitCodeMaturity', values => $E,  names => {reverse(%{$E})}},
        RL => {json => 'remediationLevel',    values => $RL, names => {reverse(%{$RL})}},
        RC => {json => 'reportConfidence',    values => $RC, names => {reverse(%{$RC})}},

        # Environmental
        CR  => {json => 'confidentialityRequirement',    values => $CR,  names => {reverse(%{$CR})}},
        IR  => {json => 'integrityRequirement',          values => $IR,  names => {reverse(%{$IR})}},
        AR  => {json => 'availabilityRequirement',       values => $AR,  names => {reverse(%{$AR})}},
        MAV => {json => 'modifiedAttackVector',          values => $MAV, names => {reverse(%{$MAV})}},
        MAC => {json => 'modifiedAttackComplexity',      values => $MAC, names => {reverse(%{$MAC})}},
        MPR => {json => 'modifiedPrivilegesRequired',    values => $MPR, names => {reverse(%{$MPR})}},
        MUI => {json => 'modifiedUserInteraction',       values => $MUI, names => {reverse(%{$MUI})}},
        MS  => {json => 'modifiedScope',                 values => $MS,  names => {reverse(%{$MS})}},
        MC  => {json => 'modifiedConfidentialityImpact', values => $MC,  names => {reverse(%{$MC})}},
        MI  => {json => 'modifiedIntegrityImpact',       values => $MI,  names => {reverse(%{$MI})}},
        MA  => {json => 'modifiedAvailabilityImpact',    values => $MA,  names => {reverse(%{$MA})}},

    };
}


# CVSS v4.0 constants

use constant CVSS4_SCORE_SEVERITY => CVSS3_SCORE_SEVERITY();

use constant CVSS4_NOT_DEFINED_VALUE => 'X';

use constant CVSS4_VECTOR_STRING_REGEX =>
    qr{^CVSS:4[.]0/AV:[NALP]/AC:[LH]/AT:[NP]/PR:[NLH]/UI:[NPA]/VC:[HLN]/VI:[HLN]/VA:[HLN]/SC:[HLN]/SI:[HLN]/SA:[HLN](/E:[XAPU])?(/CR:[XHML])?(/IR:[XHML])?(/AR:[XHML])?(/MAV:[XNALP])?(/MAC:[XLH])?(/MAT:[XNP])?(/MPR:[XNLH])?(/MUI:[XNPA])?(/MVC:[XNLH])?(/MVI:[XNLH])?(/MVA:[XNLH])?(/MSC:[XNLH])?(/MSI:[XNLHS])?(/MSA:[XNLHS])?(/S:[XNP])?(/AU:[XNY])?(/R:[XAUI])?(/V:[XDC])?(/RE:[XLMH])?(/U:(X|Clear|Green|Amber|Red))?$};

use constant CVSS4_MAX_COMPOSED => {
    eq1 => {
        0 => ['AV:N/PR:N/UI:N/'],
        1 => ['AV:A/PR:N/UI:N/', 'AV:N/PR:L/UI:N/', 'AV:N/PR:N/UI:P/'],
        2 => ['AV:P/PR:N/UI:N/', 'AV:A/PR:L/UI:P/']
    },
    eq2 => {0 => ['AC:L/AT:N/'], 1 => ['AC:H/AT:N/', 'AC:L/AT:P/']},
    eq3 => {
        0 => {
            0 => ['VC:H/VI:H/VA:H/CR:H/IR:H/AR:H/'],
            1 => ['VC:H/VI:H/VA:L/CR:M/IR:M/AR:H/', 'VC:H/VI:H/VA:H/CR:M/IR:M/AR:M/']
        },
        1 => {
            0 => ['VC:L/VI:H/VA:H/CR:H/IR:H/AR:H/', 'VC:H/VI:L/VA:H/CR:H/IR:H/AR:H/'],
            1 => [
                'VC:L/VI:H/VA:L/CR:H/IR:M/AR:H/', 'VC:L/VI:H/VA:H/CR:H/IR:M/AR:M/',
                'VC:H/VI:L/VA:H/CR:M/IR:H/AR:M/', 'VC:H/VI:L/VA:L/CR:M/IR:H/AR:H/',
                'VC:L/VI:L/VA:H/CR:H/IR:H/AR:M/'
            ]
        },
        2 => {1 => ['VC:L/VI:L/VA:L/CR:H/IR:H/AR:H/']},
    },
    eq4 => {
        0 => ['SC:H/SI:S/SA:S/'],
        1 => ['SC:H/SI:H/SA:H/'],
        2 => ['SC:L/SI:L/SA:L/']

    },
    eq5 => {0 => ['E:A/'], 1 => ['E:P/'], 2 => ['E:U/']},
};

use constant CVSS4_LOOKUP_GLOBAL => {
    '000000' => 10.0,
    '000001' => 9.9,
    '000010' => 9.8,
    '000011' => 9.5,
    '000020' => 9.5,
    '000021' => 9.2,
    '000100' => 10.0,
    '000101' => 9.6,
    '000110' => 9.3,
    '000111' => 8.7,
    '000120' => 9.1,
    '000121' => 8.1,
    '000200' => 9.3,
    '000201' => 9.0,
    '000210' => 8.9,
    '000211' => 8.0,
    '000220' => 8.1,
    '000221' => 6.8,
    '001000' => 9.8,
    '001001' => 9.5,
    '001010' => 9.5,
    '001011' => 9.2,
    '001020' => 9.0,
    '001021' => 8.4,
    '001100' => 9.3,
    '001101' => 9.2,
    '001110' => 8.9,
    '001111' => 8.1,
    '001120' => 8.1,
    '001121' => 6.5,
    '001200' => 8.8,
    '001201' => 8.0,
    '001210' => 7.8,
    '001211' => 7.0,
    '001220' => 6.9,
    '001221' => 4.8,
    '002001' => 9.2,
    '002011' => 8.2,
    '002021' => 7.2,
    '002101' => 7.9,
    '002111' => 6.9,
    '002121' => 5.0,
    '002201' => 6.9,
    '002211' => 5.5,
    '002221' => 2.7,
    '010000' => 9.9,
    '010001' => 9.7,
    '010010' => 9.5,
    '010011' => 9.2,
    '010020' => 9.2,
    '010021' => 8.5,
    '010100' => 9.5,
    '010101' => 9.1,
    '010110' => 9.0,
    '010111' => 8.3,
    '010120' => 8.4,
    '010121' => 7.1,
    '010200' => 9.2,
    '010201' => 8.1,
    '010210' => 8.2,
    '010211' => 7.1,
    '010220' => 7.2,
    '010221' => 5.3,
    '011000' => 9.5,
    '011001' => 9.3,
    '011010' => 9.2,
    '011011' => 8.5,
    '011020' => 8.5,
    '011021' => 7.3,
    '011100' => 9.2,
    '011101' => 8.2,
    '011110' => 8.0,
    '011111' => 7.2,
    '011120' => 7.0,
    '011121' => 5.9,
    '011200' => 8.4,
    '011201' => 7.0,
    '011210' => 7.1,
    '011211' => 5.2,
    '011220' => 5.0,
    '011221' => 3.0,
    '012001' => 8.6,
    '012011' => 7.5,
    '012021' => 5.2,
    '012101' => 7.1,
    '012111' => 5.2,
    '012121' => 2.9,
    '012201' => 6.3,
    '012211' => 2.9,
    '012221' => 1.7,
    '100000' => 9.8,
    '100001' => 9.5,
    '100010' => 9.4,
    '100011' => 8.7,
    '100020' => 9.1,
    '100021' => 8.1,
    '100100' => 9.4,
    '100101' => 8.9,
    '100110' => 8.6,
    '100111' => 7.4,
    '100120' => 7.7,
    '100121' => 6.4,
    '100200' => 8.7,
    '100201' => 7.5,
    '100210' => 7.4,
    '100211' => 6.3,
    '100220' => 6.3,
    '100221' => 4.9,
    '101000' => 9.4,
    '101001' => 8.9,
    '101010' => 8.8,
    '101011' => 7.7,
    '101020' => 7.6,
    '101021' => 6.7,
    '101100' => 8.6,
    '101101' => 7.6,
    '101110' => 7.4,
    '101111' => 5.8,
    '101120' => 5.9,
    '101121' => 5.0,
    '101200' => 7.2,
    '101201' => 5.7,
    '101210' => 5.7,
    '101211' => 5.2,
    '101220' => 5.2,
    '101221' => 2.5,
    '102001' => 8.3,
    '102011' => 7.0,
    '102021' => 5.4,
    '102101' => 6.5,
    '102111' => 5.8,
    '102121' => 2.6,
    '102201' => 5.3,
    '102211' => 2.1,
    '102221' => 1.3,
    '110000' => 9.5,
    '110001' => 9.0,
    '110010' => 8.8,
    '110011' => 7.6,
    '110020' => 7.6,
    '110021' => 7.0,
    '110100' => 9.0,
    '110101' => 7.7,
    '110110' => 7.5,
    '110111' => 6.2,
    '110120' => 6.1,
    '110121' => 5.3,
    '110200' => 7.7,
    '110201' => 6.6,
    '110210' => 6.8,
    '110211' => 5.9,
    '110220' => 5.2,
    '110221' => 3.0,
    '111000' => 8.9,
    '111001' => 7.8,
    '111010' => 7.6,
    '111011' => 6.7,
    '111020' => 6.2,
    '111021' => 5.8,
    '111100' => 7.4,
    '111101' => 5.9,
    '111110' => 5.7,
    '111111' => 5.7,
    '111120' => 4.7,
    '111121' => 2.3,
    '111200' => 6.1,
    '111201' => 5.2,
    '111210' => 5.7,
    '111211' => 2.9,
    '111220' => 2.4,
    '111221' => 1.6,
    '112001' => 7.1,
    '112011' => 5.9,
    '112021' => 3.0,
    '112101' => 5.8,
    '112111' => 2.6,
    '112121' => 1.5,
    '112201' => 2.3,
    '112211' => 1.3,
    '112221' => 0.6,
    '200000' => 9.3,
    '200001' => 8.7,
    '200010' => 8.6,
    '200011' => 7.2,
    '200020' => 7.5,
    '200021' => 5.8,
    '200100' => 8.6,
    '200101' => 7.4,
    '200110' => 7.4,
    '200111' => 6.1,
    '200120' => 5.6,
    '200121' => 3.4,
    '200200' => 7.0,
    '200201' => 5.4,
    '200210' => 5.2,
    '200211' => 4.0,
    '200220' => 4.0,
    '200221' => 2.2,
    '201000' => 8.5,
    '201001' => 7.5,
    '201010' => 7.4,
    '201011' => 5.5,
    '201020' => 6.2,
    '201021' => 5.1,
    '201100' => 7.2,
    '201101' => 5.7,
    '201110' => 5.5,
    '201111' => 4.1,
    '201120' => 4.6,
    '201121' => 1.9,
    '201200' => 5.3,
    '201201' => 3.6,
    '201210' => 3.4,
    '201211' => 1.9,
    '201220' => 1.9,
    '201221' => 0.8,
    '202001' => 6.4,
    '202011' => 5.1,
    '202021' => 2.0,
    '202101' => 4.7,
    '202111' => 2.1,
    '202121' => 1.1,
    '202201' => 2.4,
    '202211' => 0.9,
    '202221' => 0.4,
    '210000' => 8.8,
    '210001' => 7.5,
    '210010' => 7.3,
    '210011' => 5.3,
    '210020' => 6.0,
    '210021' => 5.0,
    '210100' => 7.3,
    '210101' => 5.5,
    '210110' => 5.9,
    '210111' => 4.0,
    '210120' => 4.1,
    '210121' => 2.0,
    '210200' => 5.4,
    '210201' => 4.3,
    '210210' => 4.5,
    '210211' => 2.2,
    '210220' => 2.0,
    '210221' => 1.1,
    '211000' => 7.5,
    '211001' => 5.5,
    '211010' => 5.8,
    '211011' => 4.5,
    '211020' => 4.0,
    '211021' => 2.1,
    '211100' => 6.1,
    '211101' => 5.1,
    '211110' => 4.8,
    '211111' => 1.8,
    '211120' => 2.0,
    '211121' => 0.9,
    '211200' => 4.6,
    '211201' => 1.8,
    '211210' => 1.7,
    '211211' => 0.7,
    '211220' => 0.8,
    '211221' => 0.2,
    '212001' => 5.3,
    '212011' => 2.4,
    '212021' => 1.4,
    '212101' => 2.4,
    '212111' => 1.2,
    '212121' => 0.5,
    '212201' => 1.0,
    '212211' => 0.3,
    '212221' => 0.1,
};

use constant CVSS4_MAX_SEVERITY => {
    eq1    => {0 => 1,                1 => 4, 2 => 5},
    eq2    => {0 => 1,                1 => 2},
    eq3eq6 => {0 => {0 => 7, 1 => 6}, 1 => {0 => 8, 1 => 8}, 2 => {1 => 10}},
    eq4    => {0 => 6,                1 => 5,                2 => 4},
    eq5    => {0 => 1,                1 => 1,                2 => 1},
};

use constant CVSS4_METRIC_GROUPS => {
    base          => [qw(AV AC AT PR UI VC VI VA SC SI SA)],
    threat        => [qw(E)],
    environmental => [qw(CR IR AR MAV MAC MAT MPR MUI MVC MVI MVA MSC MSI MSA)],
    supplemental  => [qw(S AU R V RE U)],
};

use constant CVSS4_ATTRIBUTES => {

    # Base
    attackVector              => 'AV',
    attackComplexity          => 'AC',
    attackRequirements        => 'AT',
    privilegesRequired        => 'PR',
    userInteraction           => 'UI',
    vulnConfidentialityImpact => 'VC',
    vulnIntegrityImpact       => 'VI',
    vulnAvailabilityImpact    => 'VA',
    subConfidentialityImpact  => 'SC',
    subIntegrityImpact        => 'SI',
    subAvailabilityImpact     => 'SA',

    # Threat
    exploitMaturity => 'E',

    # Environmental
    confidentialityRequirement        => 'CR',
    integrityRequirement              => 'IR',
    availabilityRequirement           => 'AR',
    modifiedAttackVector              => 'MAV',
    modifiedAttackComplexity          => 'MAC',
    modifiedAttackRequirements        => 'MAT',
    modifiedPrivilegesRequired        => 'MPR',
    modifiedUserInteraction           => 'MUI',
    modifiedVulnConfidentialityImpact => 'MVC',
    modifiedVulnIntegrityImpact       => 'MVI',
    modifiedVulnAvailabilityImpact    => 'MVA',
    modifiedSubConfidentialityImpact  => 'MSC',
    modifiedSubIntegrityImpact        => 'MSI',
    modifiedSubAvailabilityImpact     => 'MSA',

    # Supplemental
    Safety                      => 'S',
    Automatable                 => 'AU',
    Recovery                    => 'R',
    valueDensity                => 'V',
    vulnerabilityResponseEffort => 'RE',
    providerUrgency             => 'U',

};

use constant CVSS4_METRIC_VALUES => {

    AV => [qw(N A L P)],
    AC => [qw(L H)],
    AT => [qw(N P)],
    PR => [qw(N L H)],
    UI => [qw(N P A)],
    VC => [qw(H L N)],
    VI => [qw(H L N)],
    VA => [qw(H L N)],
    SC => [qw(H L N)],
    SI => [qw(H L N)],
    SA => [qw(H L N)],

    E => [qw(X A P U)],

    CR  => [qw(X H M L)],
    IR  => [qw(X H M L)],
    AR  => [qw(X H M L)],
    MAV => [qw(X N A L P)],
    MAC => [qw(X L H)],
    MAT => [qw(X N P)],
    MPR => [qw(X N L H)],
    MUI => [qw(X N P A)],
    MVC => [qw(X H L N)],
    MVI => [qw(X H L N)],
    MVA => [qw(X H L N)],
    MSC => [qw(X H L N)],
    MSI => [qw(X S H L N)],
    MSA => [qw(X S H L N)],

    S  => [qw(X N P)],
    AU => [qw(X N Y)],
    R  => [qw(X A U I)],
    V  => [qw(X D C)],
    RE => [qw(X L M H)],
    U  => [qw(X Clear Green Amber Red)],

};

sub CVSS4_METRIC_NAMES {

    # Base
    my $AV = {N => 'NETWORK', A => 'ADJACENT', L => 'LOCAL', P => 'PHYSICAL'};
    my $AC = {L => 'LOW',     H => 'HIGH'};
    my $AT = {N => 'NONE',    P => 'PRESENT'};
    my $PR = {N => 'NONE',    L => 'LOW',     H => 'HIGH'};
    my $UI = {N => 'NONE',    P => 'PASSIVE', A => 'ACTIVE'};
    my $VC = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $VI = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $VA = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $SC = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $SI = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $SA = {H => 'HIGH',    L => 'LOW',     N => 'NONE'};

    # Threat
    my $E = {X => 'NOT_DEFINED', A => 'ATTACKED', P => 'PROOF_OF_CONCEPT', U => 'UNREPORTED'};

    # Environmental
    my $CR  = {X => 'NOT_DEFINED', H => 'HIGH',    M => 'MEDIUM',   L => 'LOW'};
    my $IR  = {X => 'NOT_DEFINED', H => 'HIGH',    M => 'MEDIUM',   L => 'LOW'};
    my $AR  = {X => 'NOT_DEFINED', H => 'HIGH',    M => 'MEDIUM',   L => 'LOW'};
    my $MAV = {X => 'NOT_DEFINED', N => 'NETWORK', A => 'ADJACENT', L => 'LOCAL', P => 'PHYSICAL'};
    my $MAC = {X => 'NOT_DEFINED', L => 'LOW',     H => 'HIGH'};
    my $MAT = {X => 'NOT_DEFINED', N => 'NONE',    P => 'PRESENT'};
    my $MPR = {X => 'NOT_DEFINED', N => 'NONE',    L => 'LOW',     H => 'HIGH'};
    my $MUI = {X => 'NOT_DEFINED', N => 'NONE',    P => 'PASSIVE', A => 'ACTIVE'};
    my $MVC = {X => 'NOT_DEFINED', H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $MVI = {X => 'NOT_DEFINED', H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $MVA = {X => 'NOT_DEFINED', H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $MSC = {X => 'NOT_DEFINED', H => 'HIGH',    L => 'LOW',     N => 'NONE'};
    my $MSI = {X => 'NOT_DEFINED', S => 'SAFETY',  H => 'HIGH',    L => 'LOW', N => 'NEGLIGIBLE'};
    my $MSA = {X => 'NOT_DEFINED', S => 'SAFETY',  H => 'HIGH',    L => 'LOW', N => 'NEGLIGIBLE'};

    # Supplemental
    my $S  = {X => 'NOT_DEFINED', N     => 'NEGLIGIBLE', P     => 'PRESENT'};
    my $AU = {X => 'NOT_DEFINED', N     => 'NO',         Y     => 'YES'};
    my $R  = {X => 'NOT_DEFINED', A     => 'AUTOMATIC',  U     => 'USER', I => 'IRRECOVERABLE'};
    my $V  = {X => 'NOT_DEFINED', D     => 'DIFFUSE',    C     => 'CONCENTRATED'};
    my $RE = {X => 'NOT_DEFINED', L     => 'LOW',        M     => 'MODERATE', H     => 'HIGH'};
    my $U  = {X => 'NOT_DEFINED', Clear => 'CLEAR',      Green => 'GREEN',    Amber => 'AMBER', Red => 'RED'};

    return {
        AV => {json => 'attackVector',              values => $AV, names => {reverse(%{$AV})}},
        AC => {json => 'attackComplexity',          values => $AC, names => {reverse(%{$AC})}},
        AT => {json => 'attackRequirements',        values => $AT, names => {reverse(%{$AT})}},
        PR => {json => 'privilegesRequired',        values => $PR, names => {reverse(%{$PR})}},
        UI => {json => 'userInteraction',           values => $UI, names => {reverse(%{$UI})}},
        VC => {json => 'vulnConfidentialityImpact', values => $VC, names => {reverse(%{$VC})}},
        VI => {json => 'vulnIntegrityImpact',       values => $VI, names => {reverse(%{$VI})}},
        VA => {json => 'vulnAvailabilityImpact',    values => $VA, names => {reverse(%{$VA})}},
        SC => {json => 'subConfidentialityImpact',  values => $SC, names => {reverse(%{$SC})}},
        SI => {json => 'subIntegrityImpact',        values => $SI, names => {reverse(%{$SI})}},
        SA => {json => 'subAvailabilityImpact',     values => $SA, names => {reverse(%{$SA})}},

        E => {json => 'exploitMaturity', values => $SA, names => {reverse(%{$E})}},

        CR  => {json => 'confidentialityRequirement',        values => $CR,  names => {reverse(%{$CR})}},
        IR  => {json => 'integrityRequirement',              values => $IR,  names => {reverse(%{$IR})}},
        AR  => {json => 'availabilityRequirement',           values => $AR,  names => {reverse(%{$AR})}},
        MAV => {json => 'modifiedAttackVector',              values => $MAV, names => {reverse(%{$MAV})}},
        MAC => {json => 'modifiedAttackComplexity',          values => $MAC, names => {reverse(%{$MAC})}},
        MAT => {json => 'modifiedAttackRequirements',        values => $MAT, names => {reverse(%{$MAT})}},
        MPR => {json => 'modifiedPrivilegesRequired',        values => $MPR, names => {reverse(%{$MPR})}},
        MUI => {json => 'modifiedUserInteraction',           values => $MUI, names => {reverse(%{$MUI})}},
        MVC => {json => 'modifiedVulnConfidentialityImpact', values => $MVC, names => {reverse(%{$MVC})}},
        MVI => {json => 'modifiedVulnIntegrityImpact',       values => $MVI, names => {reverse(%{$MVI})}},
        MVA => {json => 'modifiedVulnAvailabilityImpact',    values => $MVA, names => {reverse(%{$MVA})}},
        MSC => {json => 'modifiedSubConfidentialityImpact',  values => $MSC, names => {reverse(%{$MSC})}},
        MSI => {json => 'modifiedSubIntegrityImpact',        values => $MSI, names => {reverse(%{$MSI})}},
        MSA => {json => 'modifiedSubAvailabilityImpact',     values => $MSA, names => {reverse(%{$MSA})}},

        S  => {json => 'Safety',                      values => $S,  names => {reverse(%{$S})}},
        AU => {json => 'Automatable',                 values => $AU, names => {reverse(%{$AU})}},
        R  => {json => 'Recovery',                    values => $R,  names => {reverse(%{$R})}},
        V  => {json => 'valueDensity',                values => $V,  names => {reverse(%{$V})}},
        RE => {json => 'vulnerabilityResponseEffort', values => $RE, names => {reverse(%{$RE})}},
        U  => {json => 'providerUrgency',             values => $U,  names => {reverse(%{$U})}},
    };

}

1;
__END__

=pod

=head1 NAME

CVSS::Constants - Internal constants

=head1 DESCRIPTION

These are constants for internal CVSS use.

=head1 SEE ALSO

L<CVSS>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CVSS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CVSS>

    git clone https://github.com/giterlizzi/perl-CVSS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
