return +{
    'main2_overwritten_by_sub2_scalar' => 'n1',
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
        'n1',
        'n2',
        'n3',
        {
            'n4' => 'n5',
            'n6' => 'n7'
        }
    ],
    'main2_overwritten_by_sub2_array' => [
        'n1',
        'n2',
        'n3',
        {
            'n4' => 'n5',
            'n6' => 'n7'
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
        'n5' => [
            'n6',
            'n7',
            'n8'
        ],
        'n3' => 'n4',
        'n1' => 'n2'
    },
    'main2_overwritten_by_sub2_hash' => {
        'n5' => [
            'n6',
            'n7',
            'n8'
        ],
        'n3' => 'n4',
        'n1' => 'n2'
    },
    'main1_overwritten_by_sub1_scalar' => 'n1',
    'main1_only_scalar' => 'i'
};
