import sys

sys.path.append('dash/dash-renderer')

import dash_renderer as renderer
import json

print(json.dumps({
    '_js_dist_dependencies': renderer._js_dist_dependencies,
    '_js_dist': renderer._js_dist
    }, indent=4))
