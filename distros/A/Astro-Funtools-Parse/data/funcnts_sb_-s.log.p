$c = {
       'source' => {
                     'regions' => {
                                    'regions' => [
                                                   'annulus(4164,4239,0,38.5198,n=2)'
                                                 ],
                                    'title' => 'source_region(s)'
                                  },
                     'table' => {
                                  'names' => [
                                               'reg',
                                               'counts',
                                               'pixels',
                                               'sumcnts',
                                               'sumpix'
                                             ],
                                  'records' => [
                                                 {
                                                   'reg' => '1',
                                                   'sumcnts' => '5416.000',
                                                   'sumpix' => '1177',
                                                   'pixels' => '1177',
                                                   'counts' => '5416.000'
                                                 },
                                                 {
                                                   'reg' => '2',
                                                   'sumcnts' => '39086.000',
                                                   'sumpix' => '4669',
                                                   'pixels' => '3492',
                                                   'counts' => '33670.000'
                                                 }
                                               ],
                                  'widths' => [
                                                4,
                                                12,
                                                9,
                                                12,
                                                9
                                              ],
                                  'comments' => [
                                                  ' summed_source_data'
                                                ]
                                }
                   },
       'hdr' => {
                  'source' => {
                                'data_file' => 'acisf05124N001_evt2_gsf_ds_lc_sorted.fits',
                                'arcsec/pixel' => '0.492'
                              },
                  'column units' => {
                                      'area' => 'arcsec**2',
                                      'surf_bri' => 'cnts/arcsec**2',
                                      'surf_err' => 'cnts/arcsec**2'
                                    },
                  'background' => {
                                    'data_file' => 'acisf05124N001_evt2_gsf_ds_lc_sorted.fits',
                                    'arcsec/pixel' => '0.492'
                                  }
                },
       'sum_bkgd_sub' => {
                           'table' => {
                                        'names' => [
                                                     'upto',
                                                     'net_counts',
                                                     'error',
                                                     'background',
                                                     'berror',
                                                     'area',
                                                     'surf_bri',
                                                     'surf_err'
                                                   ],
                                        'records' => [
                                                       {
                                                         'area' => '284.91',
                                                         'background' => '27.478',
                                                         'berror' => '2.632',
                                                         'upto' => '1',
                                                         'net_counts' => '5388.522',
                                                         'error' => '73.641',
                                                         'surf_bri' => '18.913',
                                                         'surf_err' => '0.258'
                                                       },
                                                       {
                                                         'area' => '1130.20',
                                                         'background' => '109.000',
                                                         'berror' => '10.440',
                                                         'upto' => '2',
                                                         'net_counts' => '38977.000',
                                                         'error' => '197.977',
                                                         'surf_bri' => '34.487',
                                                         'surf_err' => '0.175'
                                                       }
                                                     ],
                                        'widths' => [
                                                      4,
                                                      12,
                                                      9,
                                                      12,
                                                      9,
                                                      9,
                                                      9,
                                                      9
                                                    ],
                                        'comments' => [
                                                        ' summed background-subtracted results'
                                                      ]
                                      }
                         },
       'bkgd' => {
                   'regions' => {
                                  'regions' => [
                                                 'annulus(4264,4223,0,38.5198,n=2)'
                                               ],
                                  'title' => 'background_region(s)'
                                },
                   'table' => {
                                'names' => [
                                             'reg',
                                             'counts',
                                             'pixels'
                                           ],
                                'records' => [
                                               {
                                                 'reg' => 'all',
                                                 'pixels' => '4669',
                                                 'counts' => '109.000'
                                               }
                                             ],
                                'widths' => [
                                              4,
                                              12,
                                              9
                                            ],
                                'comments' => [
                                                ' background_data'
                                              ]
                              }
                 },
       'bkgd_sub' => {
                       'table' => {
                                    'names' => [
                                                 'reg',
                                                 'net_counts',
                                                 'error',
                                                 'background',
                                                 'berror',
                                                 'area',
                                                 'surf_bri',
                                                 'surf_err'
                                               ],
                                    'records' => [
                                                   {
                                                     'net_counts' => '5388.522',
                                                     'reg' => '1',
                                                     'area' => '284.91',
                                                     'background' => '27.478',
                                                     'error' => '73.641',
                                                     'surf_bri' => '18.913',
                                                     'berror' => '2.632',
                                                     'surf_err' => '0.258'
                                                   },
                                                   {
                                                     'net_counts' => '33588.478',
                                                     'reg' => '2',
                                                     'area' => '845.29',
                                                     'background' => '81.522',
                                                     'error' => '183.660',
                                                     'surf_bri' => '39.736',
                                                     'berror' => '7.808',
                                                     'surf_err' => '0.217'
                                                   }
                                                 ],
                                    'widths' => [
                                                  4,
                                                  12,
                                                  9,
                                                  12,
                                                  9,
                                                  9,
                                                  9,
                                                  9
                                                ],
                                    'comments' => [
                                                    ' background-subtracted results'
                                                  ]
                                  }
                     }
     };
