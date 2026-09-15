-- Local override of the xmake-repo package recipe for libsdl3_ttf. This tree is
-- shipped inside the Exotic::SDL3 distribution under recipes/ and registered as a
-- local xmake repository by Alien::Xrepo::Base (via `install_opts local_repos`).
-- xmake consults locally registered repositories before the bundled xmake-repo,
-- so this recipe wins over the upstream copy.
--
-- Deviations from packages/l/libsdl3_ttf/xmake.lua in xmake-repo:
--   * freetype is forced to a SHARED build. A static libfreetype.a (xmake-built
--     or Homebrew) records its own deps (-lz, -lbz2, -lpng16, ...) only as
--     link-time requirements that neither librarydeps() nor a bare pkg-config
--     call surfaces on CI (no pkg-config on macOS runners; xmake's freetype2.pc
--     is not on PKG_CONFIG_PATH). A shared libfreetype carries those deps
--     itself, so linking a SHARED libsdl3_ttf needs no extra transitive
--     libraries on any platform. (The consumer installs this package with
--     kind => 'shared' for FFI via Affix.)
--   * on_install passes -DFREETYPE_INCLUDE_DIR_ft2build and
--     -DFREETYPE_INCLUDE_DIR_freetype2 instead of the single
--     -DFREETYPE_INCLUDE_DIRS that CMake's FindFreetype ignores.
--   * on Windows, "freetype" is added to the `packagedeps` of the cmake install
--     so xmake generates a FindFreetype module for CMake; hand-passed
--     -DFREETYPE_* cache vars otherwise get lost on some toolchains.
--   * freetype's `zlib` config is disabled (default is true). With it enabled the
--     freetype build on Windows only passes -DZLIB_* vars when its zlib dep
--     resolves non-system; when it doesn't, CMake's `find_package(ZLIB REQUIRED)`
--     fails the whole install. TTF itself needs no gzip'd font support, so disable
--     zlib to keep the freetype build self-contained everywhere.
-- Keep this file in sync with the upstream recipe when bumping versions.
--
package("libsdl3_ttf")
    set_homepage("https://github.com/libsdl-org/SDL_ttf/")
    set_description("Simple DirectMedia Layer text rendering library")
    set_license("zlib")

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::sdl3-ttf")
    elseif is_plat("linux") then
        add_extsources("pacman::sdl3_ttf", "apt::libsdl3-ttf-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sdl3_ttf")
    end

    add_urls("https://www.libsdl.org/projects/SDL_ttf/release/SDL3_ttf-$(version).zip",
             "https://github.com/libsdl-org/SDL_ttf/releases/download/release-$(version)/SDL3_ttf-$(version).zip", { alias = "archive" })
    add_urls("https://github.com/libsdl-org/SDL_ttf.git", {alias = "github", submodules = false})

    add_versions("archive:3.2.2", "d38c2078630e015777aafa1a1ce627df4323114a920c313274346c372ba0d19d")
    add_versions("archive:3.2.0", "ea75fa02ab328cccdff8bf36d2ec891e445e94fa301cd0ef34c662e24d30b704")

    add_versions("github:3.2.2", "release-3.2.2")
    add_versions("github:3.2.0", "release-3.2.0")

    add_deps("cmake")
    -- Freetype must be shared AND built from source. A STATIC libfreetype.a
    -- (xmake-built or Homebrew) records its own deps (-lz, -lbz2, ...) only as
    -- link-time requirements that neither librarydeps() nor a bare pkg-config
    -- call surfaces on CI (no pkg-config on macOS runners; xmake's freetype2.pc
    -- is not on PKG_CONFIG_PATH). A shared libfreetype carries those deps
    -- itself, so linking a SHARED libsdl3_ttf needs no extra transitive
    -- libraries anywhere. `system = false` keeps xmake from satisfying freetype
    -- from a Homebrew/apt static lib despite the shared config (the fetch would
    -- otherwise prefer the system source and return its static archive).
    add_deps("freetype", {configs = {shared = true, zlib = false}, system = false})

    add_configs("harfbuzz", {description = "Use harfbuzz to improve text shaping", default = false, type = "boolean"})
    add_configs("plutosvg", {description = "Use plutosvg for color emoji support", default = false, type = "boolean"})
    if is_plat("wasm") then
        add_configs("shared", {description = "Build shared library.", default = false, type = "boolean", readonly = true})
    end

    if is_host("windows") then
        set_policy("platform.longpaths", true)
    end

    if on_check then
        on_check("android", function (package)
            if package:config("harfbuzz") then
                local ndk = package:toolchain("ndk"):config("ndkver")
                assert(ndk and tonumber(ndk) > 22, "package(libsdl3_ttf) dep(harfbuzz) require ndk version > 22")
            end
        end)
    end

    on_load(function (package)
        -- libsdl3_ttf 3.2.0 requires libsdl3 >= 3.2.6
        package:add("deps", "libsdl3 >=3.2.6", { configs = { shared = package:config("shared") }})
        if package:config("harfbuzz") then
            package:add("deps", "harfbuzz")
        end
        if package:config("plutosvg") then
            package:add("deps", "plutosvg", "plutovg")
        end
    end)

    on_install(function (package)
        local configs = {"-DSDLTTF_SAMPLES=OFF", "-DSDLTTF_VENDORED=OFF"}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DSDLTTF_HARFBUZZ=" .. (package:config("harfbuzz") and "ON" or "OFF"))
        table.insert(configs, "-DSDLTTF_PLUTOSVG=" .. (package:config("plutosvg") and "ON" or "OFF"))
        local freetype = package:dep("freetype")
        if freetype then
            local fetchinfo = freetype:fetch()
            if fetchinfo then
                local includedirs = table.wrap(fetchinfo.includedirs or fetchinfo.sysincludedirs)
                if #includedirs > 0 then
                    -- Freetype fix: see the header comment at the top of this file.
                    table.insert(configs, "-DFREETYPE_INCLUDE_DIR_ft2build=" .. table.concat(includedirs, ";"))
                    table.insert(configs, "-DFREETYPE_INCLUDE_DIR_freetype2=" .. table.concat(includedirs, ";"))
                end
                local libfiles = table.wrap(fetchinfo.libfiles)
                if #libfiles > 0 then
                    table.insert(configs, "-DFREETYPE_LIBRARY=" .. libfiles[1])
                end
            end
        end
        local install_deps = {"plutovg"}
        if package:is_plat("windows") then
            -- Let xmake generate the FindFreetype module for CMake; hand-passed
            -- -DFREETYPE_* cache vars are unreliable on some Windows toolchains.
            table.insert(install_deps, "freetype")
        end
        import("package.tools.cmake").install(package, configs, {packagedeps = install_deps})
    end)

    on_test(function (package)
        assert(package:has_cfuncs("TTF_Init", {includes = "SDL3_ttf/SDL_ttf.h"}))
    end)