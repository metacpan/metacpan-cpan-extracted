-- Local override of the xmake-repo package recipe for libsdl3.
--
-- Deviations from packages/l/libsdl3/xmake.lua in xmake-repo:
--   * builds sdl3 v 3.4.18
--   * gates the add_extsources() system path on a minimum version
--   * declares a Windows/vcpkg extsource; upstream declares none on Windows
-- Keep this file in sync with the upstream recipe when bumping versions.
--
package("libsdl3")
    set_homepage("https://www.libsdl.org/")
    set_description("Simple DirectMedia Layer")
    set_license("zlib")

    -- Oldest system SDL3 we will link against. Bump this together with the 3.4.18
    -- add_versions() entry below; the two are the same release and must not drift.
    local _MIN_SYSTEM_VERSION = "3.4.18"

    if is_plat("mingw") and is_subhost("msys") then
        add_extsources("pacman::SDL3")
    elseif is_plat("linux") then
        add_extsources("pacman::sdl3", "apt::libsdl3-dev")
    elseif is_plat("macosx") then
        add_extsources("brew::sdl3")
    elseif is_plat("windows") then
        add_extsources("vcpkg::sdl3")
    end

    -- add_extsources() only says *where* to look, never *which versions are
    -- acceptable*, so xmake happily resolves apt::libsdl3-dev on Ubuntu 25.10
    -- (3.4.2) or a stale brew/vcpkg tree and reports success. The extension
    -- libraries are built from source against 3.4.18 headers, so a system core
    -- older than that mixes two ABIs in one link and breaks at runtime rather
    -- than at configure time.
    --
    -- The probe below mirrors the candidate list xmake's own fallback uses
    -- (extsources, then the bare package name -- @see
    -- core/package/package.lua:1978-1998), so the only thing it changes is which
    -- versions are accepted. The bare name is self:name(), i.e. "libsdl3", while
    -- the vcpkg port is "sdl3", so bare-name probing never reaches vcpkg; the
    -- explicit vcpkg::sdl3 extsource declared above is what puts vcpkg (and this
    -- gate) on the Windows candidate list at all.
    on_fetch(function (self, opt)
        if not opt.system then
            -- Not a system install: let the normal from-xmake-repo path run.
            return
        end

        local semver = import("core.base.semver")
        local names = {}
        if not self:is_thirdparty() then
            table.join2(names, self:extsources())
        end
        table.insert(names, self:name())

        for _, name in ipairs(names) do
            -- self:find_package() rather than the global find_package(): it
            -- defaults to system-only for non-xmake:: names, which is what the
            -- fallback below uses, so we test the same package it would pick.
            local fetchinfo = self:find_package(name, {system = true})
            if fetchinfo then
                local found = fetchinfo.version
                -- pkgconfig-style managers report a plain semver; vcpkg reports
                -- "<semver>-<portrevision>" (libsdl3_3.4.18-1_x64-windows.list).
                -- semver reads that as a 3.4.18 pre-release, so a perfectly
                -- current vcpkg SDL3 would look older than it is. Drop the port
                -- revision before comparing.
                local comparable = found and found:gsub("%-%d+$", "")
                -- try() returns the try-function's return values directly, not
                -- (ok, result) -- @see core/sandbox/modules/try.lua:132 -- so an
                -- unparseable version arrives here as nil rather than false.
                local satisfies = try {
                    function () return semver.satisfies(comparable, ">=" .. _MIN_SYSTEM_VERSION) end
                }
                if satisfies then
                    return fetchinfo
                end
                -- Returning false (not nil) is what disables xmake's extsource
                -- fallback -- @see core/package/package.lua _fetch_library -- so
                -- the too-old package is skipped and we build the pinned release
                -- instead. Returning nil here would hand it straight back.
                print(string.format("libsdl3: system SDL3 %s is older than %s, building from source",
                      found or "of unknown version", _MIN_SYSTEM_VERSION))
                return false
            end
        end
    end)

    add_urls("https://www.libsdl.org/release/SDL3-$(version).zip",
             "https://github.com/libsdl-org/SDL/releases/download/release-$(version)/SDL3-$(version).zip", { alias = "archive" })
    add_urls("https://github.com/libsdl-org/SDL.git", { alias = "github" })

    add_versions("archive:3.4.18", "9cd42377704398796071b8597cd7e21da254a43bad98c4199739647adc13fa6f")
    add_versions("archive:3.4.16", "5f399fdfbc040169ef4418a3cb99ccc5a0641681f7ccc1da66eeec3c97fa4076")
    add_versions("archive:3.4.12", "3d4de8967a49c0451e775a0c1e9022092c19fdef41ba38a83fcf031c5a6496e2")
    add_versions("archive:3.4.4", "6bd4fbb665f77899a488b381c5b6e9681fc57c60b669738f985fea714f3456c5")
    add_versions("archive:3.4.2", "4954d436c95c42aa258d4eb3fb95f8ecc5d7a3dc411f0f41ac2692d34b9b9e9c")
    add_versions("archive:3.4.0", "9ac2debb493e0d3e13dbd2729fb91f4bfeb00a0f4dff5e04b73cc9bac276b38d")
    add_versions("archive:3.2.28", "24a30069af514a6c6b773bdc8ccca8b321661b251381acc1daeebf8c8f4a109a")
    add_versions("archive:3.2.26", "739356eef1192fff9d641c320a8f5ef4a10506b8927def4b9ceb764c7e947369")
    add_versions("archive:3.2.22", "3d60068b1e5c83c66bb14c325dfef46f8fcc380735b4591de6f5e7b9738929d1")
    add_versions("archive:3.2.16", "0cc7430fb827c1f843e31b8b26ba7f083b1eeb8f6315a65d3744fd4d25b6c373")
    add_versions("archive:3.2.14", "46a17d3ea71fe2580a7f43ca7da286c5b9106dd761e2fd5533bb113e5d86b633")
    add_versions("archive:3.2.10", "01d9ab20fc071b076be91df5396b464b4ef159e93b2b2addda1cc36750fc1f29")
    add_versions("archive:3.2.8", "7f8ff5c8246db4145301bc122601a5f8cef25ee2c326eddb3e88668849c61ddf")
    add_versions("archive:3.2.6", "665e5aa2a613affe099a38d61257ecc5ef4bf38b109d915147aa8b005399d68a")
    add_versions("archive:3.2.2", "58d8adc7068d38923f918e0bdaa9c4948f93d9ba204fe4de8cc6eaaf77ad6f82")
    add_versions("archive:3.2.0", "abe7114fa42edcc8097856787fa5d37f256d97e365b71368b60764fe7c10e4f8")

    add_versions("github:3.4.18", "release-3.4.18")
    add_versions("github:3.4.16", "release-3.4.16")
    add_versions("github:3.4.12", "release-3.4.12")
    add_versions("github:3.4.4", "release-3.4.4")
    add_versions("github:3.4.2", "release-3.4.2")
    add_versions("github:3.4.0", "release-3.4.0")
    add_versions("github:3.2.28", "release-3.2.28")
    add_versions("github:3.2.26", "release-3.2.26")
    add_versions("github:3.2.22", "release-3.2.22")
    add_versions("github:3.2.16", "release-3.2.16")
    add_versions("github:3.2.14", "release-3.2.14")
    add_versions("github:3.2.10", "release-3.2.10")
    add_versions("github:3.2.8", "release-3.2.8")
    add_versions("github:3.2.6", "release-3.2.6")
    add_versions("github:3.2.2", "release-3.2.2")
    add_versions("github:3.2.0", "release-3.2.0")

    add_patches("3.4.0", "patches/3.4.0/fix-ios.patch", "feffa146aa825f97fc431f115f3990a7a0ad0214d05a9765f2cfbd3633465bf8")

    -- Not on Windows: that platform installs from the official prebuilt package, so
    -- there is nothing to compile and cmake plus the GL headers would only be pulled
    -- in to sit unused (a source-built freetype/cmake is also the slow, flaky part of
    -- the Windows/ARM leg, see issue #3).
    if not is_plat("windows") then
        add_deps("cmake", "egl-headers", "opengl-headers")
    end

    if is_plat("linux", "bsd", "cross") then
        add_configs("x11", {description = "Enables X11 support", default = true, type = "boolean"})
        add_configs("x11_shared", {description = "Dynamically load X11 support", default = true, type = "boolean"})
        add_configs("wayland", {description = "Enables Wayland support", default = nil, type = "boolean"})
        add_configs("wayland_shared", {description = "Dynamically load Wayland support", default = true, type = "boolean"})
    end

    if is_plat("wasm") then
        add_cxflags("-sUSE_SDL=0")
        add_configs("threads", {description = "Enables pthread support", default = false, type = "boolean"})
    end

    on_load(function (package)
        if package:is_plat("linux", "android", "cross") then
            -- Enable Wayland by default except when cross-compiling (wayland package doesn't support cross-compilation yet)
            if package:config("wayland") == nil and not package:is_cross() then
                package:config_set("wayland", true)
            end
        end
        if package:is_plat("wasm") and package:config("threads") then
            package:add("cxflags", "-pthread", "-matomics", "-mbulk-memory")
            package:add("ldflags", "-pthread")
        end
        if package:is_plat("windows") then
            package:add("deps", "ninja")
            package:set("policy", "package.cmake_generator.ninja", true)
        end
        if package:is_plat("linux", "bsd", "cross") and package:config("x11") then
            local deplibs = {"libx11", "libxcb", "libxext", "libxcursor", "libxfixes", "libxi", "libxrandr", "libxrender", "libxss"}
            local depconfig = package:config("x11_shared") and {private = true, configs = {shared = true}} or nil
            for _, lib in ipairs(deplibs) do
                package:add("deps", lib, depconfig)
            end
        end
        if package:is_plat("linux", "bsd", "cross") and package:config("wayland") then
            if package:config("wayland_shared") then
                package:add("deps", "wayland", {private = true, configs = {shared = true}})
            else
                package:add("deps", "wayland")
            end
        end
        if package:is_plat("linux") and not package:is_cross() then
            -- Fail fast with the apt command instead of letting xrepo bootstrap
            -- the whole X11 stack from source: those builds are slow and flaky
            -- (libtool relink races under parallel jobs have wedged CI for hours).
            -- Each X11 library decides system-vs-source via its own upstream
            -- recipe's add_extsources, so presence of these -dev packages is
            -- what makes xrepo use the system libs.
            local probes = {
                {"libx11-dev",       "/usr/include/X11/Xlib.h"},
                {"libxcb1-dev",      "/usr/include/xcb/xcb.h"},
                {"libxext-dev",      "/usr/include/X11/extensions/shape.h"},
                {"libxfixes-dev",    "/usr/include/X11/extensions/Xfixes.h"},
                -- Debian/Ubuntu ships this header under X11/Xcursor/; there is
                -- no /usr/include/X11/Xcursor.h to probe for.
                {"libxcursor-dev",   "/usr/include/X11/Xcursor/Xcursor.h"},
                {"libxrandr-dev",    "/usr/include/X11/extensions/Xrandr.h"},
                {"libxi-dev",        "/usr/include/X11/extensions/XInput2.h"},
                {"libxrender-dev",   "/usr/include/X11/extensions/Xrender.h"},
                {"libxss-dev",       "/usr/include/X11/extensions/scrnsaver.h"},
                {"libxkbcommon-dev", "/usr/include/xkbcommon/xkbcommon.h"},
                {"libwayland-dev",   "/usr/include/wayland-client.h"},
            }
            local missing = {}
            for _, probe in ipairs(probes) do
                if not os.isfile(probe[2]) then
                    table.insert(missing, probe[1])
                end
            end
            if #missing > 0 then
                raise("libsdl3 requires the system X11/Wayland development packages. Missing: %s.\nInstall them with:\n  sudo apt-get update && sudo apt-get install -y %s",
                      table.concat(missing, ", "),
                      "libx11-dev libxcb1-dev libxext-dev libxfixes-dev libxcursor-dev libxrandr-dev libxi-dev libxrender-dev libxss-dev libxkbcommon-dev libwayland-dev")
            end
        end
        local libsuffix = package:is_debug() and "d" or ""
        if not package:config("shared") then
            if package:is_plat("windows", "mingw") then
                package:add("syslinks", "user32", "gdi32", "winmm", "imm32", "ole32", "oleaut32", "version", "uuid", "advapi32", "setupapi", "shell32")
            elseif package:is_plat("linux", "bsd") then
                package:add("syslinks", "pthread", "dl")
                if package:is_plat("bsd") then
                    package:add("syslinks", "usbhid")
                end
            elseif package:is_plat("android") then
                package:add("syslinks", "dl", "log", "android", "GLESv1_CM", "GLESv2", "OpenSLES")
            elseif package:is_plat("iphoneos", "macosx") then
                package:add("frameworks", "AudioToolbox", "AVFoundation", "CoreAudio", "CoreHaptics", "CoreMedia", "CoreVideo", "Foundation", "GameController", "Metal", "QuartzCore", "CoreFoundation", "UniformTypeIdentifiers")
		        package:add("syslinks", "iconv")
                if package:is_plat("macosx") then
                    package:add("frameworks", "Cocoa", "Carbon", "ForceFeedback", "IOKit")
                else
                    package:add("frameworks", "CoreBluetooth", "CoreGraphics", "CoreMotion", "OpenGLES", "UIKit")
                end
		    end
        end
    end)

    on_install(function (package)
        -- Windows has no working from-source story for this family yet
        -- (https://github.com/Perl-SDL3/Alien-SDL3.pm/issues/3: the toolchain in play is
        -- x64 gcc running under emulation on windows-11-arm, and xmake picks the ARM64
        -- host arch, which no part of the toolchain can actually produce). The Alien is
        -- consumed through FFI, which needs only a shared library and its headers, so
        -- install the matching official prebuilt package instead of compiling:
        --   * MSVC  -> <prefix>-devel-<ver>-VC.zip     root/lib/{x86,x64,arm64}
        --   * MinGW -> <prefix>-devel-<ver>-mingw.zip  <triple>/{bin,include,lib}
        -- The flavour follows the *toolchain*, not the OS, so that on_test -- which
        -- compiles and links a probe after every install -- gets an import library the
        -- active linker can use: gcc wants the mingw .dll.a, cl wants the VC .lib. The
        -- archive for the other toolchain is never fetched. The sub-arch comes from
        -- package:arch(), which Alien::SDL3's install_opts() pins to $Config{archname},
        -- so the DLL handed back is the one the running Perl can load.
        -- This helper is deliberately defined *inside* the callback: sandbox.new()
        -- setfenv()s only the script itself (core/sandbox/sandbox.lua:239), so a
        -- chunk-level local function keeps the package script's read-only `os`
        -- (isfile/isdir/files/dirs only -- no mkdir/cp/rm) and dies on first use.
        local function _install_windows_prebuilt(package, github_repo, asset_prefix, linkname)
            local ver = package:version_str()
            local msvc = package:has_tool("cxx", "cl")
            local flavour = msvc and "VC" or "mingw"
            local url = string.format(
                "https://github.com/libsdl-org/%s/releases/download/release-%s/%s-devel-%s-%s.zip",
                github_repo, ver, asset_prefix, ver, flavour)

            local cachedir = package:cachedir()
            os.mkdir(cachedir)
            local zipfile = path.join(cachedir, string.format("%s-devel-%s-%s.zip", asset_prefix, ver, flavour))
            if not os.isfile(zipfile) then
                import("net.http.download")(url, zipfile)
            end
            local workdir = path.join(package:builddir(), "prebuilt")
            os.tryrm(workdir)
            os.mkdir(workdir)
            import("utils.archive.extract")(zipfile, workdir)

            -- Both flavours unpack to <prefix>-<version>/ at the archive root.
            local root = path.join(workdir, string.format("%s-%s", asset_prefix, ver))
            if not os.isdir(root) then
                raise("package(%s): %s unpacked without its %s/ root", package:name(), zipfile, asset_prefix .. "-" .. ver)
            end

            local lower = (package:arch() or ""):lower()
            local is_x64 = lower:find("x86_64", 1, true) or lower:find("amd64", 1, true) or lower:find("x64", 1, true)
            local is_arm = lower:find("arm64", 1, true) or lower:find("aarch64", 1, true)

            local incdir, libdir, bindir
            if msvc then
                local vcarch = is_arm and "arm64" or (is_x64 and "x64" or "x86")
                incdir = path.join(root, "include")
                libdir = path.join(root, "lib", vcarch)
                bindir = libdir
            else
                if not (is_x64 or is_arm) then
                    -- only i686/x86_64 mingw builds are published
                    raise("package(%s): no mingw prebuilt for arch %q; use the MSVC toolchain instead",
                          package:name(), package:arch() or "?")
                end
                if is_arm then
                    raise("package(%s): SDL publishes no mingw arm64 prebuilt; use the MSVC toolchain instead",
                          package:name())
                end
                local triple = "x86_64-w64-mingw32"
                incdir = path.join(root, triple, "include")
                libdir = path.join(root, triple, "lib")
                bindir = path.join(root, triple, "bin")
            end
            if not os.isdir(libdir) then
                raise("package(%s): prebuilt archive has no %s for arch %q", package:name(), libdir, package:arch() or "?")
            end

            local installdir = package:installdir()
            local incdst = path.join(installdir, "include")
            local libdst = path.join(installdir, "lib")
            local bindst = path.join(installdir, "bin")
            os.mkdir(incdst); os.mkdir(libdst); os.mkdir(bindst)

            -- Copy the *contents* of include/: a bare-dir cp would nest it as include/SDL3-3.4.18.
            os.cp(path.join(incdir, "*"), incdst)
            -- Import libraries for the linker.
            for _, pattern in ipairs({"*.lib", "*.dll.a", "*.a"}) do
                os.cp(path.join(libdir, pattern), libdst)
            end
            -- Runtime DLLs. Alien::Xrepo picks libpath -- the file FFI dlopens, which
            -- t/affix.t load_library()s -- from the first .dll found in linkdirs, so the
            -- DLL must live in lib/ as well as in bin/, which is what puts it on the
            -- PATH that xmake builds for on_test.
            os.cp(path.join(libdir, "*.dll"), libdst)
            os.cp(path.join(bindir, "*.dll"), bindst)
            os.cp(path.join(bindir, "*.dll"), libdst)
            -- image/mixer ship codec DLLs in a side directory of the VC layout only.
            local optional = path.join(libdir, "optional")
            if os.isdir(optional) then
                os.cp(path.join(optional, "*.dll"), libdst)
                os.cp(path.join(optional, "*.dll"), bindst)
            end

            -- CMake normally publishes these; a manual install has to declare them, or
            -- _generate_configs() raises "links not found!" for every consumer (including
            -- this package's own on_test). The dir entries must be relative: the manifest
            -- reader joins them onto the installdir itself
            -- (modules/package/manager/xmake/find_package.lua:81,144), so an absolute path
            -- would come back as installdir/C:/... and find_library would find nothing.
            package:add("includedirs", "include")
            package:add("linkdirs", "lib")
            package:add("bindirs", "bin")
            package:add("links", linkname)
        end

        if package:is_plat("windows") then
            _install_windows_prebuilt(package, "SDL", "SDL3", "SDL3")
            return
        end

        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        table.insert(configs, "-DSDL_TEST_LIBRARY=OFF")
        table.insert(configs, "-DSDL_EXAMPLES=OFF")
        if package:is_plat("linux", "bsd", "cross") then
            table.insert(configs, "-DSDL_X11=" .. (package:config("x11") and "ON" or "OFF"))
            table.insert(configs, "-DSDL_X11_SHARED=" .. (package:config("x11_shared") and "ON" or "OFF"))
            table.insert(configs, "-DSDL_X11_XTEST=OFF")
            table.insert(configs, "-DSDL_WAYLAND=" .. (package:config("wayland") and "ON" or "OFF"))
            table.insert(configs, "-DSDL_WAYLAND_SHARED=" .. (package:config("wayland_shared") and "ON" or "OFF"))
        end
        if package:is_plat("wasm") and package:config("threads") then
            table.insert(configs, "-DSDL_PTHREADS=ON")
        end

        local cflags
        local packagedeps
        if not package:is_plat("wasm") then
            packagedeps = table.join2(packagedeps or {}, {"egl-headers", "opengl-headers"})
        end

        if package:is_plat("linux", "bsd", "cross") then
            packagedeps = table.join2(packagedeps or {}, {"libxcursor", "libxext", "libxfixes", "libxcb", "libx11", "libxi", "libxrandr", "libxrender", "libxss", "xorgproto", "wayland"})
        elseif package:is_plat("wasm") then
            -- emscripten enables USE_SDL by default which will conflict with libsdl headers
            cflags = {"-sUSE_SDL=0"}
        end

        local includedirs = {}
        for _, depname in ipairs(packagedeps) do
            local dep = package:dep(depname)
            if dep then
                local depfetch = dep:fetch()
                if depfetch then
                    for _, includedir in ipairs(depfetch.includedirs or depfetch.sysincludedirs) do
                        table.insert(includedirs, includedir)
                    end
                end
            end
        end
        if #includedirs > 0 then
            includedirs = table.unique(includedirs)
            table.insert(configs, "-DCMAKE_INCLUDE_PATH=" .. table.concat(includedirs, ";"))
            cflags = cflags or {}
            for _, includedir in ipairs(includedirs) do
                table.insert(cflags, "-I" .. includedir)
            end
        end
        import("package.tools.cmake").install(package, configs, {cflags = cflags})
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <SDL3/SDL.h>
            int main(int argc, char** argv) {
                SDL_Init(0);
                SDL_Quit();
                return 0;
            }
        ]]}));
    end)
