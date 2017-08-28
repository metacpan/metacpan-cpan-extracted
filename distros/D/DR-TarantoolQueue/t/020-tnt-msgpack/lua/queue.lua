local log = require 'log'
local json = require 'json'
local fio = require 'fio'

box.cfg{ listen  = os.getenv('PRIMARY_PORT'), readahead = 10240000 }

box.schema.user.create('test', { password = 'test' })
box.schema.user.grant('test', 'read,write,execute', 'universe')

local megaqueue_path =
    fio.pathjoin(
        fio.dirname(
            fio.dirname(
                fio.dirname(
                    fio.dirname(
                        arg[0]
                    )
                )
            )
        ),
        'megaqueue'
    )

package.path =
    fio.pathjoin(megaqueue_path, '?.lua;') ..
    fio.pathjoin(megaqueue_path, '?/init.lua;') ..
    package.path




_G.queue = require('megaqueue')
queue:init()
