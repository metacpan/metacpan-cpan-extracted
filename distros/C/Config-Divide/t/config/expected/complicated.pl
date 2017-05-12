return +{
    'main2_overwritten_by_sub2_scalar' => 'o1',
    'main1_only_hash' => {
        'i1' => 'i2',
        'i3' => 'i4',
        'i5' => [
            'i6',
            'i7'
        ]
    },
    'main2_only_array' => [
        'i1',
        'i2',
        {
            'i1' => 'i2',
            'i3' => 'i4'
        }
    ],
    'main1_overwritten_by_sub1_array' => [
        'o1',
        'o2',
        {
            'o3' => 'o4'
        }
    ],
    'main2_overwritten_by_sub2_array' => [
        'o1',
        'o2',
        {
            'o3' => 'o4'
        }
    ],
    'main2_only_scalar' => 'i',
    'main1_only_array' => [
        'i1',
        'i2',
        {
            'i1' => 'i2',
            'i3' => 'i4'
        }
    ],
    'main2_only_hash' => {
        'i1' => 'i2',
        'i3' => 'i4',
        'i5' => [
            'i6',
            'i7'
        ]
    },
    'main1_overwritten_by_sub1_hash' => {
        'o1' => 'o2',
        'o3' => [
            'o4',
            'o5',
            'o6'
        ]
    },
    'main2_overwritten_by_sub2_hash' => {
        'o1' => 'o2',
        'o3' => [
            'o4',
            'o5',
            'o6'
        ]
    },
    'main1_overwritten_by_sub1_scalar' => 'o1',
    'main1_only_scalar' => 'i'
};
