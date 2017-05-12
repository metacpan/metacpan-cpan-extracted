print(os.getenv('PRIMARY_PORT'))

local box = require 'box';
box.cfg{ listen  = os.getenv('PRIMARY_PORT') }
